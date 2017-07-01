# SHACHI


# setup
```
plenv install 5.20.1
plenv local 5.20.1
plenv rehash
plenv install-cpanm
cpanm Carton
carton install

npm install
```

# deploy
```
fab --hosts=`cat config/hosts` update
fab --hosts=`cat config/hosts` restart
```

# local
```
./script/localup
```
