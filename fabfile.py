from fabric.api import *
# For Sakura FreeBSD
env.shell = "/usr/local/bin/bash -l -c"
env.hosts = ['sidb@sidb.sakura.ne.jp']
home_dir = '/home/sidb/www/Shachi'
pidfile = './pid'

def update():
    with settings(warn_only=True):
        if run("test -d %s" % home_dir).failed:
            run("git clone git@github.com:skozawa/Shachi.git %s" % home_dir)
    with cd(home_dir):
        run('git pull')
        run('git submodule update --init')
        run('plenv local 5.20.1')
        run('plenv rehash')
        run('carton install --deployment')
        put('config/db.production', 'config/db.production')

def start():
    with cd(home_dir):
        print('start server')
        # FIXME: stop by C-c
        run("PIDFILE=%s script/run.sh >& /dev/null 2>&1" % pidfile, pty=False)

def stop():
    with cd(home_dir):
        print("stop server")
        run("kill `cat %s`" % pidfile)

def restart():
    with cd(home_dir):
        print('restart server')
        run("kill -s HUP `cat %s`" % pidfile)

