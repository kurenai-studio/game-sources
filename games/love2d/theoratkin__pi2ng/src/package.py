#!/usr/bin/python3

import os
import sys
import subprocess
import shutil
import glob
import tarfile

gamename = 'PI2NG'

lovever = '11.3'
gamever = '1.0'

gamedir = './game'
resdir = gamedir + '/res'
builddir = './build'
dldir = builddir + '/.downloads'

lovefile = '%s/%s-%s.love' % (builddir, gamename, gamever)
desktopfile = 'desktop'
iconpng = resdir + '/icon.png'
iconico = 'media/icon.ico'
appimagetool = dldir + '/appimagetool'

cwd = os.getcwd()

lovelink = 'https://github.com/love2d/love/releases/download/' + lovever + '/'
appimagelink = \
    'https://github.com/AppImage/AppImageKit' \
    '/releases/download/continuous/appimagetool-x86_64.AppImage'


#####################################################################
# Utility functions #################################################
#####################################################################

def zip(wd:str, path:str, files:list):
    """
    Create ZIP archive.

    wd -- directory to chroot to
    path -- archive file
    files -- files to archive
    """
    os.chdir(wd)
    cmd = ['zip', '-9', '-r']
    # Updating the archive if it already exists.
    if os.path.exists(path):
        cmd.append('-u')
    cmd += [path] + files
    p = subprocess.Popen(cmd)
    p.wait()
    os.chdir(cwd)


def unzip(path:str, outdir:str):
    """
    Extract ZIP archive.

    path -- ZIP file to extract
    outdir -- output directory
    """
    p = subprocess.Popen(['unzip', path, '-d', outdir])
    p.wait()


def download(url:str, out:str):
    """
    Download a file.

    url -- source URL
    out -- output file
    """
    p = subprocess.Popen(['wget', url, '-O', out, '-q', '--show-progress'])
    p.wait()


def cat(files:list, out:str):
    """
    Concatenate several files into one.

    files -- files to concatenate
    out -- output file
    """
    with open(out, 'wb') as outfile:
        for fname in files:
            with open(fname, 'rb') as infile:
                outfile.write(infile.read())


def make_executable(path:str):
    """Mark a file as executable."""
    mode = os.stat(path).st_mode
    mode |= (mode & 0o444) >> 2    # copy R bits to X
    os.chmod(path, mode)


def make_appimage(src:str, dst:str):
    """
    Create AppImage.

    src -- source directory
    dst -- output file
    """
    # Downloading appimagetool.
    if not os.path.exists(appimagetool):
        download(appimagelink, appimagetool)
        make_executable(appimagetool)

    cmd = [appimagetool, src, dst]
    p = subprocess.Popen(cmd)
    p.wait()


#####################################################################
# Packaging #########################################################
#####################################################################

def windows(arch:str):
    """Package the game for Windows."""

    print('Building for win-' + arch)

    outdir   = builddir + '/win' + arch
    filename = 'love-%s-win%s' % (lovever, arch)
    zipfile  = dldir + '/' + filename + '.zip'
    lovedir  = dldir + '/' + filename
    loveexec = lovedir + '/love.exe'
    gameexec = gamename + '.exe'

    # Creating output directory.
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    # Downloading LOVE relase from GitHub.
    if not os.path.exists(zipfile):
        download(lovelink + filename + '.zip', zipfile)

    # Extracting the archive.
    if not os.path.exists(lovedir):
        unzip(zipfile, dldir)

    # Concatenating the executable and *.love file.
    cat([loveexec, lovefile], outdir + '/' + gameexec)

    # Copying DLL files and the license.
    files = glob.glob(lovedir + '/*.dll')
    files.append(lovedir + '/license.txt')
    for f in files:
        print('Copying %s -> %s' % (f, outdir))
        shutil.copy2(f, outdir)

    # Copying icon.
    print('Copying icon')
    shutil.copy2(iconico, outdir + '/' + gamename + '.ico')


def linux(arch:str):
    """Package the game for Linux using AppImage."""

    print('Building for linux-' + arch)
    
    filename  = 'love-%s-linux-%s' % (lovever, arch)
    appdir    = dldir + '/' + filename
    apprun    = appdir + '/AppRun'
    bindir    = appdir + '/usr/bin'
    loveexec  = bindir + '/love'
    gameexec  = bindir + '/' + gamename
    targzfile = appdir + '.tar.gz'
    imgfile   = '%s/%s-%s-%s.AppImage' % (builddir, gamename, gamever, arch)

    # Downloading LOVE relase from GitHub.
    if not os.path.exists(targzfile):
        download(lovelink + filename + '.tar.gz', targzfile)

    # Extracting the tar.gz archive
    if not os.path.exists(appdir):
        tar = tarfile.open(targzfile, "r:gz")
        tar.extractall(dldir)
        tar.close()

        # Renaming the extracted directory.
        shutil.move(dldir + '/dest', appdir)

    # Fusing the game inside the executable.
    cat([loveexec, lovefile], gameexec)
    make_executable(gameexec)

    # Creating AppRun
    if not os.path.exists(apprun):
        # Renaming love shell script to AppRun.
        shutil.move(appdir + '/love', apprun)

        # Replacing executable name inside AppRun.
        with open(apprun, "r+") as f:
            data = f.read().replace('/usr/bin/love', '/usr/bin/' + gamename)
            f.seek(0)
            f.write(data)
            f.truncate()

    # Copying desktop file.
    shutil.copy2(desktopfile, '%s/%s.desktop' % (appdir, gamename))

    # Copying icon.
    shutil.copy2(iconpng, '%s/%s.png' % (appdir, gamename))

    # Removing unnecessary files.
    toremove = [appdir + '/love.svg', appdir + '/love.desktop.in']
    for f in toremove:
        if os.path.exists(f):
            os.remove(f)

    # Making appimage.
    make_appimage(appdir, imgfile)


#####################################################################
# Main ##############################################################
#####################################################################

known_targets = [
    'all',
    'win', 'win32', 'win64',
    'linux', 'linux32', 'linux64'
]
targets = sys.argv[1:]

# Checking targets.
if len(targets) == 0 or not set(targets) <= set(known_targets):
    print('Unknown target specified. Available targets:')
    for target in known_targets:
        print('  ' + target)
    exit(1)

# Creating build directory.
if not os.path.exists(builddir):
    os.makedirs(builddir)

# Creating downloads directory.
if not os.path.exists(dldir):
    os.makedirs(dldir)

# Creating *.love file.
zip(gamedir, '../' + lovefile, ['.'])

# Packaging everything.
if 'all' in targets:
    targets.append('win')
    targets.append('linux')

# Packaging for Windows.
if 'win' in targets:
    targets.append('win64')
    targets.append('win32')

if 'win64' in targets:
    windows('64')

if 'win32' in targets:
    windows('32')

# Packaging for Linux.
if 'linux' in targets:
    targets.append('linux64')
    targets.append('linux32')

if 'linux64' in targets:
    linux('x86_64')

if 'linux32' in targets:
    linux('i686')
