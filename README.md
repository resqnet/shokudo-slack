# [wip]shokudo-slack

native extentionを利用しているためLambda環境でbundle installする必要があります  
`docker run -v `pwd`:/var/task -it lambci/lambda:build-ruby2.5 bundle install --path vendor/bundle`  

deploy  
`sls deploy`
