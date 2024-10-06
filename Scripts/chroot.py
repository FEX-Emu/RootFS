#!/bin/python3

# Usage:
# cd in to the rootfs directory
# ./chroot.py chroot
# You will be prompted for your password to mount container paths
# At the end you should be inside the chroot

from enum import Enum
import sys
from dataclasses import dataclass, field
import subprocess
import shutil
import logging
import os
import pwd
import platform

logger = logging.getLogger()
logger.setLevel(logging.INFO)

class Command(Enum):
    UNBREAK = 0
    BREAK = 1
    CHROOT = 2

@dataclass
class HostApplicationsClass:
    RequiredHostApplications = [
        "sudo",
        "patchelf",
        "readelf",
        "ldd",
        "mount",
        "umount",
        "mountpoint",
    ]

    RequireProgramsForChrooting = [
        "FEXInterpreter",
        "FEXServer",
        "chroot",
    ]

    def CheckIfProgramWorks(self, Program):
        from shutil import which
        if which(Program) is None:
            logging.critical("Host program '{}' isn't available and is required!".format(Program))
            sys.exit(1)

    def CheckProgramsExist(self, ExecutionCommand):
        for Program in self.RequiredHostApplications:
            self.CheckIfProgramWorks(Program)

        if ExecutionCommand == Command.CHROOT:
            for Program in self.RequireProgramsForChrooting:
                self.CheckIfProgramWorks(Program)

@dataclass
class FEXInterpreterDependenciesClass:
    Path: str
    Depends: list
    Interpreter: str

    def __init__(self):
        from shutil import which
        self.Path = which("FEXInterpreter")
        self.Depends = []
        self.Interpreter = None
        assert self.Path is not None

        logging.debug("FEXInterpreter at: '{}'".format(self.Path))
        self.GetDepends()
        self.GetProgramInterpreter()

    # Extracts shared library dependencies from FEXInterpreter
    def GetDepends(self):
        Output = subprocess.check_output(["ldd", self.Path])
        # Convert byte object to string
        Output = Output.decode('ascii')

        for Line in Output.split('\n'):
            Line = Line.strip()

            # Skip vdso dependency
            if "vdso" in Line or len(Line) == 0:
                continue

            if " => " in Line:
                # Split paths to get filesystem path if exists.
                Split = Line.split(" => ")
                assert len(Split) == 2
                Line = Split[1]

            # Line is now in the format of `<Path> (Address)`
            # Split again to get only the library path.
            Split = Line.split(" (0x")
            assert len(Split) == 2

            Depend = Split[0]

            logging.debug("Depends: '{}' -> '{}'".format(Line, Depend))
            self.Depends.append(Depend)

    # Gets the interpreter path for FEXInterpreter .
    def GetProgramInterpreter(self):
        Output = subprocess.check_output(["readelf", "-l", self.Path])
        # Convert byte object to string
        Output = Output.decode('ascii')

        for Line in Output.split('\n'):
            Line = Line.strip()
            if "Requesting program interpreter" not in Line:
                continue
            Split = Line.split("[Requesting program interpreter: ")
            assert len(Split) == 2

            Line = Split[1]

            # Strip off the final ']'
            Line = Line[0:(len(Line)-1)]
            logging.debug("PT_INTERP: '{}'".format(Line))
            self.Interpreter = Line

            # Remove interpreter from list of depends
            # We'll handle that manually
            while self.Interpreter in self.Depends:
                self.Depends.remove(self.Interpreter)

    def CopyDependsTo(self, Path):
        for File in self.Depends:
            shutil.copy(File, Path)

        shutil.copy(self.Interpreter, Path)

    def CopyFEXInterpreterTo(self, Path):
        shutil.copy(self.Path, Path)

@dataclass
class BackupPathsClass:
    # Recursively create these folders
    CreateBackupFolders = [
        "etc/",
        "var/cache/",
        "var/lib/",
        "var/lib/dbus/",
    ]

    # Entire folders to move
    BackupFoldersToMove = [
        "boot",
        "home",
        "media",
        "mnt",
        "root",
        "srv",
        "tmp",
        "run",
        # Var folders to move
        "var/tmp",
        "var/run",
        "var/lock",
    ]

    # Folders to move only if they are empty
    BackupFoldersToMoveIfEmpty = [
        # Specifically works around wine installing things in to /opt
        "opt",
    ]

    # Files to move out of folders
    BackupFilesToMove = [
        # Bunch of etc files to move
        "etc/hosts",
        "etc/resolv.conf",
        "etc/timezone",
        "etc/localtime",
        "etc/passwd",
        "etc/passwd-",
        "etc/group",
        "etc/group-",
        "etc/shadow",
        "etc/shadow-",
        "etc/gshadow",
        "etc/gshadow-",
        "etc/fstab",
        "etc/hostname",
        "etc/mtab",
        "etc/subuid",
        "etc/subgid",
        "etc/machine-id",

        # Var files to move
        "var/lib/dbus/machine-id",
    ]

    def __init__(self):
        return

    def BackupBreak(self, BackupPath, ScriptPath):
        # Create backup folder itself
        try:
            os.makedirs(BackupPath)
        except:
            # Non-fatal
            pass

        # First create folders required.
        for Dir in self.CreateBackupFolders:
            os.makedirs("{}/{}".format(BackupPath, Dir), exist_ok=True)

        # Move folders first
        for Dir in self.BackupFoldersToMove:
            FullScriptPath = "{}/{}".format(ScriptPath, Dir)
            FullBackupPath = "{}/{}".format(BackupPath, Dir)
            # Source, Dest
            try:
                shutil.move(FullScriptPath, FullBackupPath)
            except:
                # Non-fatal
                pass

        # Move folders if only their contents are empty.
        for Dir in self.BackupFoldersToMoveIfEmpty:
            FullScriptPath = "{}/{}".format(ScriptPath, Dir)
            FullBackupPath = "{}/{}".format(BackupPath, Dir)

            try:
                listing = os.listdir(FullScriptPath)
                if len(listing) == 0:
                    # Source, Dest
                    shutil.move(FullScriptPath, FullBackupPath)
            except:
                # Non-fatal
                pass

        # Move files now
        for File in self.BackupFilesToMove:
            FullScriptPath = "{}/{}".format(ScriptPath, File)
            FullBackupPath = "{}/{}".format(BackupPath, File)
            # Source, Dest
            try:
                shutil.move(FullScriptPath, FullBackupPath)
            except:
                # Non-fatal
                pass

    def BackupUnbreak(self, BackupPath, ScriptPath):
        # Move files now
        for File in self.BackupFilesToMove:
            FullScriptPath = "{}/{}".format(ScriptPath, File)
            FullBackupPath = "{}/{}".format(BackupPath, File)
            # Source, Dest
            try:
                shutil.move(FullBackupPath, FullScriptPath)
            except:
                # Non-fatal
                pass

        # Move folders if only their contents are empty.
        for Dir in self.BackupFoldersToMoveIfEmpty:
            FullScriptPath = "{}/{}".format(ScriptPath, Dir)
            FullBackupPath = "{}/{}".format(BackupPath, Dir)

            try:
                listing = os.listdir(FullScriptPath)
                if len(listing) == 0:
                    # Source, Dest
                    shutil.move(FullBackupPath, FullScriptPath)
            except:
                # Non-fatal
                pass

        # Move folders
        for Dir in self.BackupFoldersToMove:
            FullScriptPath = "{}/{}".format(ScriptPath, Dir)
            FullBackupPath = "{}/{}".format(BackupPath, Dir)
            # Source, Dest
            try:
                shutil.move(FullBackupPath, FullScriptPath)
            except:
                # Non-fatal
                pass

        # Now remove folders
        for Dir in self.CreateBackupFolders:
            try:
                shutil.rmtree("{}/{}".format(BackupPath, Dir))
            except:
                # Non-fatal
                pass


        # Remove backup folder itself
        try:
            shutil.rmtree(BackupPath)
        except:
            # Non-fatal
            pass

@dataclass
class MountManagerClass:
    MountPaths = [
        # mntpoint, [Mount options]
        ["proc",    ["-t", "proc", "proc"]],
        ["sys",     ["-t", "sysfs", "sysfs"]],
        ["dev",     ["-t", "devtmpfs", "udev"]],
        ["dev/pts", ["-t", "devpts", "devpts"]],
        ["tmp",     ["--rbind", "/tmp"]],
    ]

    def __init__(self):
        return

    def CheckIfMountpath(self, Path):
        Result = subprocess.run(["mountpoint", "-q", Path])
        return Result.returncode == 0

    def Break(self, ScriptPath):
        logging.info("Unmounting rootfs paths")

        for Dir in reversed(self.MountPaths):
            MountPath = "{}/{}".format(ScriptPath, Dir[0])
            assert self.CheckIfMountpath(MountPath) == True

            MountOptions = ["sudo", "umount"]
            MountOptions.append(MountPath)
            Result = subprocess.run(MountOptions)
            if not Result.returncode == 0:
                logging.error("Failed to unmount {}/{}!".format(ScriptPath, Dir[0]))

        # Remove the directories now
        for Dir in reversed(self.MountPaths):
            os.rmdir("{}/{}".format(ScriptPath, Dir[0]))

    def Unbreak(self, ScriptPath):
        for Dir in self.MountPaths:
            MountPath = "{}/{}".format(ScriptPath, Dir[0])
            assert self.CheckIfMountpath(MountPath) == False

        # First create folders required.
        for Dir in self.MountPaths:
            os.makedirs("{}/{}".format(ScriptPath, Dir[0]), exist_ok=True)

        # For some reason /tmp ends up being 0664
        assert self.CheckIfMountpath("{}/tmp".format(ScriptPath)) == False
        Result = subprocess.run(["chmod", "1777", "{}/tmp".format(ScriptPath)])
        assert Result.returncode == 0

        logging.info("Mounting rootfs paths")

        for Dir in self.MountPaths:
            MountPath = "{}/{}".format(ScriptPath, Dir[0])

            MountOptions = ["sudo", "mount"]
            MountOptions.extend(Dir[1])
            MountOptions.append(MountPath)
            Result = subprocess.run(MountOptions)
            assert Result.returncode == 0

ScriptPath = None
FEXInterpreterDependencies = None
ExecutionCommand = None

def GetScriptPath():
    global ScriptPath
    ScriptPath = os.path.abspath(os.path.dirname(sys.argv[0]))

def DoBreak():
    logging.info("Deleting FEX paths")

    FEXPath = "{}/fex/".format(ScriptPath)
    BackupPath = "{}/chroot/".format(ScriptPath)
    try:
        shutil.rmtree(FEXPath)
    except:
        # Non-fatal
        pass

    logging.info("Unmount rootfs paths")

    Result = subprocess.run(["sudo", "umount", "-l", "{}/proc".format(ScriptPath)])

    if Result.returncode != 0:
        logging.info("Failed to umount {}/proc. Might have dangling mount!".format(ScriptPath))

    Result = subprocess.run(["sudo", "umount", "-l", "{}/sys".format(ScriptPath)])
    if Result.returncode != 0:
        logging.info("Failed to umount {}/sys. Might have dangling mount!".format(ScriptPath))

    Result = subprocess.run(["sudo", "umount", "-l", "{}/dev/pts".format(ScriptPath)])
    if Result.returncode != 0:
        logging.info("Failed to umount {}/dev/pts. Might have dangling mount!".format(ScriptPath))

    Result = subprocess.run(["sudo", "umount", "-l", "{}/dev".format(ScriptPath)])
    if Result.returncode != 0:
        logging.info("Failed to umount {}/dev. Might have dangling mount!".format(ScriptPath))

    Result = subprocess.run(["sudo", "umount", "-l", "{}/tmp".format(ScriptPath)])
    if Result.returncode != 0:
        logging.info("Failed to umount {}/tmp. Might have dangling mount!".format(ScriptPath))

    # Break the rootfs image
    BackupPathsClass().BackupBreak(BackupPath, ScriptPath)

    logging.info("Fixing any potential permission issues")

    User = pwd.getpwuid(os.getuid())[0]
    if "SUDO_USER" in os.environ:
        # If executed under sudo then user that user instead.
        User = os.environ["SUDO_USER"]

    FoldersToFix = [
        "bin",
        "chroot",
        "etc",
        "lib",
        "lib64",
        "sbin",
        "usr",
        "var",
    ]

    for Dir in FoldersToFix:
        Result = subprocess.run(["sudo", "chown", "-R", "{}:{}".format(User, User), "{}/{}".format(ScriptPath, Dir)])

    return 0

def DoUnbreak():
    FEXInterpreterDependencies = FEXInterpreterDependenciesClass()

    logging.info("Creating FEX paths")
    LibPath = "{}/fex/lib64/".format(ScriptPath)
    BinPath = "{}/fex/bin/".format(ScriptPath)
    BackupPath = "{}/chroot/".format(ScriptPath)

    # Create directories that FEXInterpreter needs.
    # Continue on error, probably already existed.
    try:
        os.mkdir("{}/fex/".format(ScriptPath))
    except:
        pass

    try:
        os.mkdir(BinPath)
    except:
        pass

    try:
        os.mkdir(LibPath)
    except:
        pass

    # Copy necessary dependencies over to directories
    logging.info("Copying FEXInterpreter depends")
    FEXInterpreterDependencies.CopyDependsTo(LibPath)
    FEXInterpreterDependencies.CopyFEXInterpreterTo(BinPath)
    logging.info("Patching FEXInterpreter")

    # Change interpreter path and add an rpath to search for the binaries.
    Result = subprocess.run(["patchelf", "--set-interpreter", "/fex/lib64/{}".format(os.path.basename(FEXInterpreterDependencies.Interpreter)), "{}/FEXInterpreter".format(BinPath)])
    assert Result.returncode == 0

    # Add the new RPATH to the FEXInterpreter
    Result = subprocess.run(["patchelf", "--add-rpath", "/fex/lib64/", "{}/FEXInterpreter".format(BinPath)])
    assert Result.returncode == 0

    # Unbreak the rootfs image
    BackupPathsClass().BackupUnbreak(BackupPath, ScriptPath)

    # Setup mounts
    MountManagerClass().Unbreak(ScriptPath)
    return 0

def main():
    if len(sys.argv) < 2:
        logging.error("Usage: {} <command>".format(sys.argv[0]))
        return 1

    if sys.argv[1] == "break":
        ExecutionCommand = Command.BREAK
    elif sys.argv[1] == "unbreak":
        ExecutionCommand = Command.UNBREAK
    elif sys.argv[1] == "chroot":
        ExecutionCommand = Command.CHROOT
    else:
        logging.error("Unknown command '{}'. Only understand break, unbreak, & chroot".format(sys.argv[1]))
        return 1

    GetScriptPath()
    HostApplicationsClass().CheckProgramsExist(ExecutionCommand)

    IsArm = platform.processor() == "aarch64" or "arm" in platform.processor()
    logging.debug("Platform: {}".format(platform.processor()))

    if ExecutionCommand == Command.UNBREAK:
        return DoUnbreak()
    elif ExecutionCommand == Command.BREAK:
        return DoBreak()
    elif ExecutionCommand == Command.CHROOT:
        DoUnbreak()

        if IsArm:
            logging.info("Starting FEXServer")

            # We need to setup FEXServer to work correctly.
            # Unset FEX rootfs specifically
            os.environ["FEX_ROOTFS"] = ""
            # Set up the server socketpath
            ScriptDir = os.path.dirname(ScriptPath)
            uid = os.getuid()
            SocketPath = "{}-{}.chroot".format(uid, ScriptDir)
            os.environ["FEX_SERVERSOCKETPATH"] = SocketPath

            # Set FEX config for server socket path
            os.makedirs("{}/usr/share/fex-emu/".format(ScriptPath), exist_ok=True)
            Config = open("{}/usr/share/fex-emu/Config.json".format(ScriptPath), "w")
            ConfigText = "{{\"Config\": {{\"ServerSocketPath\":\"{}\"}}".format(SocketPath)
            Config.write(ConfigText)
            Config.close()

            # Set environment file for fex server path
            Config = open("{}/etc/environment".format(ScriptPath), "a")
            Config.write("FEX_SERVERSOCKETPATH={}\n".format(SocketPath))
            Config.close()

            subprocess.Popen(["FEXServer", "-p", "30"], start_new_session=True)

        logging.info("Chrooting in to {}".format(ScriptPath))

        ChrootArgs = ["sudo", "--preserve-env=FEX_ROOTFS,FEX_SERVERSOCKETPATH", "chroot", ScriptPath]

        if IsArm:
            ChrootArgs.append("/fex/bin/FEXInterpreter")

        ChrootArgs.append(os.environ['SHELL'])
        ChrootArgs.append("-i")
        Result = subprocess.run(ChrootArgs)

        logging.info("Returning from chroot")

        DoBreak()

    return 0

if __name__ == "__main__":
    sys.exit(main())
