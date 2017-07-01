# SHACHI

言語資源メタデータデータベースSHACHI http://shachi.org/


# setup
```
plenv install
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
