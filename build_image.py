#!/usr/bin/python3
import errno
import hashlib
import git
import os
import requests
import shutil
import sys
import subprocess
import tarfile
import telnetlib
import time
import json
from pathlib import Path
from shutil import which

NeededApplications = [
        "git",
        "qemu-img",
        "virt-format",
        "guestmount",
        "guestunmount",
        "cloud-localds",
        "pigz",
        "mksquashfs",
        "mkfs.erofs",
    ]

def CreateDir(Dir):
    try:
        os.mkdir(Dir, 0o755)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise

def CreateDirTree(Dir):
    try:
        os.makedirs(Dir)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise


def GetGitRoot():
    return subprocess.run(["git" , "rev-parse", "--show-toplevel"], stdout=subprocess.PIPE).stdout.decode().rstrip()

def DownloadImage(CacheDir, SHA256Sums, BaseURL, Image):
    with requests.get(SHA256Sums, stream = True) as r:
        with open(CacheDir + "/SHA256SUMS", "wb") as SHA256SumFile:
            shutil.copyfileobj(r.raw, SHA256SumFile)

    # Open the SHA256Sum file we just downloaded
    SHA256Sum_file = open(CacheDir + "/SHA256SUMS", "r")
    SHA256Sum = SHA256Sum_file.read()
    SHA256Sum_file.close()

    FoundImage = False
    ExpectedSHA256Sum = ""
    for line in SHA256Sum.splitlines():
        Split = line.split(" ")
        CurrentSHA256Sum = Split[0]
        CurrentImageName = Split[1][1:]
        if CurrentImageName == Image:
            FoundImage = True
            ExpectedSHA256Sum = CurrentSHA256Sum
            break

    if FoundImage == False:
        raise Exception("Couldn't find image sda256sum")

    CalculatedSHA256Sum = ""
    # Found an image, if it exists then sha256sum it, else download it again
    if os.path.exists(CacheDir + "/" + Image):
        sha256Hash = hashlib.sha256()
        Image_file = open(CacheDir + "/" + Image, "rb")
        Image_data = Image_file.read()
        Image_file.close()
        sha256Hash.update(Image_data)
        CalculatedSHA256Sum = sha256Hash.hexdigest()

    if CalculatedSHA256Sum != ExpectedSHA256Sum:
        # Calculated SHA256Sum isn't the same as expected
        # Download the new image
        with requests.get(BaseURL + Image, stream = True) as r:
            with open(CacheDir + "/" + Image, "wb") as ImageFile:
                shutil.copyfileobj(r.raw, ImageFile)
    else:
        print("\tFile hash matched. Skipping Download");

def CreateGuestVMImage(RootFSDir, LinuxImage, config_json):
    if os.system("qemu-img create -f qcow2 " + RootFSDir + "/VMData.img 30G") != 0:
        raise Exception("qemu-img create failure")

    if os.system("virt-format --filesystem=ext3 --format=qcow2 -a " + RootFSDir + "/VMData.img") != 0:
        raise Exception("virt-format failure")

    VMMountDir = RootFSDir + "/VMMount"
    CreateDir(VMMountDir)

    if os.system("guestmount -a " + RootFSDir + "/VMData.img -m /dev/sda1 " + VMMountDir) != 0:
        raise Exception("guestmount failure")

    # We need to sleep for a bit because guestmount turns in to a daemon
    time.sleep(5)

    if os.system("sync") != 0:
        raise Exception("sync failure")

    # Copy the rootfs image over to the VM image
    if os.system("cp " + LinuxImage + " " + VMMountDir) != 0:
        raise Exception("copy failed")

    GitRoot = GetGitRoot()

    # Copy over things from the git root when specified
    print("CopyFiles_Stage0")
    if ("CopyFiles_Stage0" in config_json):
        if os.system("mkdir " + VMMountDir + "/FilesCopy/") != 0:
            raise Exception("copyFiles folder failed")

        for file in config_json["CopyFiles_Stage0"]:
            BinaryPath = GitRoot + "/" + file
            # Copy in to our temporary path
            os.system("cp -rv " + BinaryPath + " " + VMMountDir + "/FilesCopy/")

    # Ensure that the guest mount has picked up the copies
    # This sometimes still falls on its face. I'm not sure how to work around it.
    time.sleep(5)

    if os.system("sync") != 0:
        raise Exception("sync failure")

    if os.system("guestunmount " + VMMountDir) != 0:
        raise Exception("umount failure")

    if os.system("sync") != 0:
        raise Exception("sync failure")

def CreateHostVMImage(RootFSDir, LinuxImage):
    if os.system("cp " + LinuxImage + " " + RootFSDir + "/Host.img") != 0:
        raise Exception("copy host image failed")

    if os.system("qemu-img resize " + RootFSDir + "/Host.img +10G") != 0:
        raise Exception("Couldn't resize host image")

    cloud_config_file = open(RootFSDir + "/cloud_config.txt", "w")
    cloud_config_file.write("#cloud-config\n")
    cloud_config_file.write("password: ubuntu\n")
    cloud_config_file.write("chpasswd: { expire: False }\n")
    cloud_config_file.write("ssh_pwauth: True\n")
    cloud_config_file.close()

    if os.system("cloud-localds " + RootFSDir + "/cloud_config.img " + RootFSDir + "/cloud_config.txt") != 0:
        raise Exception("Cloud config failure")

def Cleanup(RootFSDir):
    shutil.rmtree(RootFSDir, ignore_errors=True)

if sys.version_info[0] < 3:
    raise Exception("Python 3 or a more recent version is required.")

if (len(sys.argv) < 4):
    sys.exit("usage: %s <Config.json> <Cache directory> <RootFS Dir>" % (sys.argv[0]))

def Stage0(CacheDir, RootFSDir, config_json):
    Guest_CacheDir = CacheDir + "/Guest"
    Host_CacheDir = CacheDir + "/Host"

    CreateDirTree(Guest_CacheDir)
    CreateDirTree(Host_CacheDir)

    print("Downloading Guest")
    DownloadImage(Guest_CacheDir, config_json["Guest_SHA256Sums"], config_json["Guest_BaseURL"], config_json["Guest_Image"])

    print("Downloading Host")
    DownloadImage(Host_CacheDir, config_json["Host_SHA256Sums"], config_json["Host_BaseURL"], config_json["Host_Image"])

# We will have an image in our cache directory at this point
    LinuxImage = Guest_CacheDir + "/" + config_json["Guest_Image"]
    Host_LinuxImage = Host_CacheDir + "/" + config_json["Host_Image"]

# Grab the git sha
    GITSHA = git.Repo(search_parent_directories=True).head.object.hexsha

# XXX: Move this after we are done
    Cleanup(RootFSDir)

    CreateDirTree (RootFSDir)
    print("Creating VM Host")
    CreateHostVMImage (RootFSDir, Host_LinuxImage)

    print("Creating VM Guest")
    CreateGuestVMImage (RootFSDir, LinuxImage, config_json)

def Stage1(CacheDir, RootFSDir, config_json):
# Need to wait for some of the previous applications to give up their deferred locks
    time.sleep(5)

    NumCores = subprocess.run(["nproc"], stdout=subprocess.PIPE).stdout.decode().rstrip()
    TelnetPort = 4321
    TelnetFile = "/tmp/FEX_ROOTFS_{}".format(TelnetPort)

    for Port in range(4321, 4400):
        try:
            TelnetPort = Port
            TelnetFile = "/tmp/FEX_ROOTFS_{}".format(TelnetPort)
            Path(TelnetFile).touch(exist_ok=False)
        except FileExistsError:
            # Try again
            continue
        except:
            raise

        # Made a temporary file
        break;

    print("Telnet port {}".format(TelnetPort))
    QEmuCommand = [
        config_json["QEmu"],
        '-drive',
        'file=' + RootFSDir + '/Host.img' + ',format=qcow2',
        '-drive',
        'file=' + RootFSDir + '/cloud_config.img' + ',format=raw',
        '-drive',
        'file=' + RootFSDir + '/VMData.img' + ',format=qcow2',
        '-m',
        '16G',
        '-smp',
        NumCores,
        '-enable-kvm',
        '-nographic',
        '-nic',
        'user,model=virtio-net-pci',
        '-serial',
        'telnet:localhost:{},server'.format(TelnetPort)
    ]

    process = subprocess.Popen(QEmuCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin = subprocess.PIPE)
    for line in process.stderr:
        print(line.decode().rstrip())
        if line.decode().find("QEMU waiting for connection") != -1:
            break

    tn = telnetlib.Telnet("localhost", TelnetPort)
    print("Connected via telnet. Waiting for login")

    PrevLine = b""
    while True:
        line = tn.read_until(b"\n")
        # Sometimes the line splits badly ?
        TestLine = PrevLine + line.rstrip()
        print(line.decode().rstrip())
        # After this point the username and password will be set and we can login
        if b"running 'modules:final'" in TestLine:
            break;
        PrevLine = line.rstrip()

    Username = "ubuntu"
    print("@@@ Logging In @@@")

# This is a stupid race
# Just hammer it with a bunch of username and password pairs
    tn.write(Username.encode('ascii') + b"\n")
    tn.write(Username.encode('ascii') + b"\n")
    time.sleep(1)
    tn.write(Username.encode('ascii') + b"\n")
    tn.write(Username.encode('ascii') + b"\n")
    time.sleep(1)
    tn.write(Username.encode('ascii') + b"\n")
    tn.write(Username.encode('ascii') + b"\n")
    time.sleep(1)
    tn.write(Username.encode('ascii') + b"\n")
    tn.write(Username.encode('ascii') + b"\n")

    while True:
        line = tn.read_until(b"\n")
        print(line.decode().rstrip())
        if b"Password:" in line:
            tn.write(Username.encode('ascii') + b"\n")
            break

    def ExecuteCommand(tn, Command):
        tn.write(str.encode(Command + " ;\n"))
        time.sleep(1)

    def ExecuteCommandAndWait(tn, Command):
        eager = tn.read_very_eager()
        print(eager.decode().rstrip())

        tn.write(str.encode(Command + ' ; echo -e "\\x44\\x4f\\x4e\\x45" ;\n'))
        while True:
            line = tn.read_until(b"\n")
            print(line.decode().rstrip())
            if b"DONE" in line:
                break;

    print("Should be logged in now")

# Set up as root just to ensure we don't hit any password prompts
    ExecuteCommand(tn, "sudo su")

    ExecuteCommandAndWait(tn, "ls /dev/sd*")
    ExecuteCommandAndWait(tn, "mkdir Mount")
    ExecuteCommandAndWait(tn, "mount /dev/sdc1 Mount")
    ExecuteCommandAndWait(tn, "cd Mount")

    print("Commands_Stage1_0")
    for command in config_json["Commands_Stage1_0"]:
        ExecuteCommandAndWait(tn, command)

    print("Output rootfs now")
    ExecuteCommandAndWait(tn, "mkdir RootFS")
    ExecuteCommandAndWait(tn, "tar -I pigz -C RootFS -xf " + config_json["Guest_Image"])

    print("RemoveFiles_Stage1")
    for file in config_json["RemoveFiles_Stage1"]:
        ExecuteCommandAndWait(tn, "rm ./RootFS/" + file)

    ExecuteCommand(tn, "sudo su")

    print("Commands_Stage1")
    for command in config_json["Commands_Stage1"]:
        ExecuteCommandAndWait(tn, command)

    # Copy over things from the git root when specified
    print("CopyFiles_Stage1")
    if ("CopyFiles_Stage1" in config_json):
        ExecuteCommandAndWait(tn, "ls -l .")
        for file in config_json["CopyFiles_Stage1"]:
            BinaryPath = "./FilesCopy/" + file[0]
            # Copy in to our temporary path
            ExecuteCommandAndWait(tn, "cp -rv " + BinaryPath + " ./RootFS/" + file[1])

    print("Time to chroot!")
    ExecuteCommand(tn, "chroot RootFS")

    print("Commands_InChroot")
    for command in config_json["Commands_InChroot"]:
        ExecuteCommandAndWait(tn, command)

    Command = config_json["PKGInstallCMD"]
    Send = False
    for app in config_json["PackagesToAdd"]:
        Command = Command + " " + app
        # Maximum argument size from `getconf ARG_MAX` is 2097152
        # Lets not go right up against the limit to be safe, but get close
        MAX_COMMAND_LENGTH = 2048000
        if len(Command) > MAX_COMMAND_LENGTH:
            ExecuteCommandAndWait(tn, Command)
            Command = config_json["PKGInstallCMD"]

    # Finish the remaining installs
    ExecuteCommandAndWait(tn, Command)

    print("Commands_InChroot2")
    for command in config_json["Commands_InChroot2"]:
        ExecuteCommandAndWait(tn, command)

    ExecuteCommand(tn, "exit")

    print("Commands_Stage2")
    for command in config_json["Commands_Stage2"]:
        ExecuteCommandAndWait(tn, command)

    print("RemoveFiles_Stage2")
    for file in config_json["RemoveFiles_Stage2"]:
        ExecuteCommandAndWait(tn, "rm ./RootFS/" + file)

    print("RemoveDirs_Stage2")
    for dir in config_json["RemoveDirs_Stage2"]:
        ExecuteCommandAndWait(tn, "rm -Rf ./RootFS/" + dir)

    # Reset the terminal to make it sane
    ExecuteCommandAndWait(tn, "reset")

    ExecuteCommandAndWait(tn, "cd RootFS/")
    ExecuteCommandAndWait(tn, "tar -I pigz -cf ../Stage1_" + config_json["Guest_Image"] + " *")
    ExecuteCommandAndWait(tn, "cd ..")

    ExecuteCommand(tn, "shutdown now")

    print("Done with Stage1 Image!")

    tn.close()
    os.remove(TelnetFile)

    process.wait()

def Stage2(CacheDir, RootFSDir, config_json):
    VMMountDir = RootFSDir + "/VMMount"

    print("Mounting VM image")
    if os.system("guestmount -a " + RootFSDir + "/VMData.img -m /dev/sda1 " + VMMountDir) != 0:
        raise Exception("guestmount failure")

    # We need to sleep for a bit because guestmount turns in to a daemon
    time.sleep(5)

    if os.system("sync") != 0:
        raise Exception("sync failure")

    Stage1_RootFS = RootFSDir + "/Stage1_RootFS/"
    SquashFSTarget = RootFSDir + "/" + config_json["ImageName"] + ".sqsh"
    EroFSTarget = RootFSDir + "/" + config_json["ImageName"] + ".ero"

    CreateDir(Stage1_RootFS)

    print("Extracting Stage1 Image")

    # Extract the stage1 rootfs
    # Copy the rootfs image over to the VM image
    if os.system("tar -I pigz -xf " + VMMountDir + "/Stage1_" + config_json["Guest_Image"] + " -C " + Stage1_RootFS) != 0:
        raise Exception("copy failed")

    if os.system("guestunmount " + VMMountDir) != 0:
        raise Exception("umount failure")

    # We need to sleep for a bit because guestmount turns in to a daemon
    time.sleep(5)

    if os.system("sync") != 0:
        raise Exception("sync failure")

    OldDir = os.getcwd()
    os.chdir(Stage1_RootFS);

    print("Commands_PreInstall")
    for command in config_json["Commands_PreInstall"]:
        os.system(command)

    os.chdir(OldDir)

    GitRoot = GetGitRoot()

    print("Installing binaries")
    for Binary in config_json["BinariesToInstall"]:
        BinaryPath = GitRoot + "/" + Binary
        if os.system("tar -h --overwrite -I pigz -xf " + BinaryPath + " -C " + Stage1_RootFS) != 0:
            raise Exception("Binary install failure")

    OldDir = os.getcwd()
    os.chdir(Stage1_RootFS)

    print("Commands_Stage3")
    for command in config_json["Commands_Stage3"]:
        os.chdir(Stage1_RootFS)
        os.system(command)

    print("Repackaging image")
    if os.system("tar -I pigz -cf ../Stage2_" + config_json["Guest_Image"] + " *") != 0:
        raise Exception("tar failure")

    os.chdir(OldDir)

    print("Repackaging image to SquashsFS")
    if os.system("mksquashfs " + Stage1_RootFS + " " + SquashFSTarget + " -comp zstd") != 0:
        raise Exception("mksquashfs failure")

    print("Repackaging image to EroFS. Using LZ4HC compression level 12. Might take a while!")
    if os.system("mkfs.erofs -x-1 -zlz4hc,12 " + EroFSTarget + " " + Stage1_RootFS) != 0:
        raise Exception("mkfs.erofs failure")

    print("Completed image now at %s" % ("Stage2_" + config_json["Guest_Image"]))
    print("Completed squashfs image now at %s" % (config_json["ImageName"] + ".sqsh"))
    print("Completed EroFS image now at %s" % (config_json["ImageName"] + ".ero"))

def CheckPrograms():
    Missing = False
    for Binary in NeededApplications:
        if which(Binary) is None:
            print("Missing necessary application '{}'".format(Binary))
            Missing = True
    return not Missing

if CheckPrograms() == False:
    sys.exit(1)

CacheDir = sys.argv[2]
RootFSDir = sys.argv[3]

# Load our json file
config_file = open(sys.argv[1], "r")
config_text = config_file.read()
config_file.close()

config_json = json.loads(config_text)

Stage0(CacheDir, RootFSDir, config_json)
Stage1(CacheDir, RootFSDir, config_json)
print("Moving on to Stage2 Image")
Stage2(CacheDir, RootFSDir, config_json)

