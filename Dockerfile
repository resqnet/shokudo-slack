FROM lambci/lambda:build-ruby2.5

WORKDIR /opt

RUN curl -sL https://rpm.nodesource.com/setup_6.x | bash - \
  && yum -y install nodejs && yum -y clean all \
  && npm install -g serverless

WORKDIR /var/task/
CMD ["/bin/bash"]
