#Dockerfile to webchain-pool
#made by Skiff (skiffax)
FROM jrei/systemd-debian:latest

RUN apt-get -y update && apt-get install -y redis-server \
    golang-go \
    bash \
    nodejs
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y sudo wget openssh-server software-properties-common build-essential tcl git unzip curl python net-tools nginx

#configuring redis /etc/redis/redis.conf “supervised no” -> change it to “supervised systemd”
RUN sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
RUN chsh -s /bin/bash
ENV HOME="/root"
WORKDIR $HOME

#Installation of GO
RUN curl -O https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.13.3.linux-amd64.tar.gz
RUN echo "export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin" >> ~/.bashrc && \. ~/.bashrc

#creation user "webchain"
#RUN useradd -ms /bin/bash webchain
#RUN chown -R webchain:webchain /home/webchain

#Installation of nodejs and npm
#следующая - попытка установить ноду
#RUN apt-get install -y nodejs
#возможное решения: одно из двух
#RUN apt-get install nodejs-legacy
#RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
#RUN export HOME="/home/webchain"
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
RUN touch ~/.bashrc && chmod +x ~/.bashrc
#RUN git clone http://github.com/creationix/nvm.git /home/webchain/.nvm
RUN export NVM_DIR="$HOME/.nvm"
#RUN chmod -R 777 /home/webchain
RUN \. $HOME/.nvm/nvm.sh
RUN \. $HOME/.nvm/bash_completion
RUN bash -i -c 'nvm install v8.17.0'
RUN bash -i -c 'command -v nvm'


RUN pwd
RUN wget https://github.com/mintme-com/webchaind/releases/download/v0.8.0/webchaind-0.8.0-linux-amd64.zip
RUN unzip webchaind-0.8.0-linux-amd64.zip -d .
#RUN ls -la
#RUN \. webchain --help

#creation frontend
RUN git clone https://github.com/mintme-com/pool.git && mv pool webchain-pool
WORKDIR webchain-pool
RUN make

WORKDIR $HOME/webchain-pool/www
RUN bash -i -c "npm install -g ember-cli@2.4.3"
RUN bash -i -c "npm install -g bower"
RUN bash -i -c "npm install"
RUN bash -i -c "bower install"
RUN ls -la
RUN chmod 777 ./build.sh
RUN \. ./build.sh

#RUN ls -la $HOME
#RUN ls -la $HOME/webchain-pool/
#RUN rm $HOME/webchain-pool/config.json
COPY ./config-json/config*json $HOME/webchain-pool/
#COPY ./config-json/config-api.json $HOME/webchain-pool/
#COPY ./config-json/config-unlocker.json $HOME/webchain-pool/
#COPY ./config-json/config-payouts.json $HOME/webchain-pool/
#RUN ls -la $HOME/webchain-pool

#copy wallet
COPY mainnet/keystore/* $HOME/.webchain/mainnet/keystore/
COPY wallet.pass $HOME/


#copy services
COPY ./services-systemd/webchain* /etc/systemd/system/
#RUN ls -la /etc/systemd/system/

#configuring nginx
#переопределяем путь
#RUN sed -i 's/root \/var\/www\/html;/root $HOME\/webchain-pool\/www\/dist;/' /etc/nginx/sites-available/default
#RUN sed -i 's/root \/home\/webchain\/webchain-pool\/www\/dist;/root $HOME\/webchain-pool\/www\/dist;/' /etc/nginx/sites-available/default
COPY ./config-nginx/default /etc/nginx/sites-available/default
RUN sed -i 's/root \/var\/www\/html;/root $HOME\/webchain-pool\/www\/dist;/' /etc/nginx/sites-available/default
RUN sed -i 's/\/home\/webchain\/$HOME\webchain-pool\/www\/dist;/$HOME\/webchain-pool\/www\/dist;/' /etc/nginx/sites-available/default

#RUN chown -R webchain:webchain /home/webchain
#RUN command -v nvm
#Verify
#RUN npm -v
#RUN nvm list

#replace IP in the environment.js of pool
#RUN ls -la
#RUN pwd
#WORKDIR webchain-pool/www
#RUN ls -la
ENV IP_SERVER="192.168.1.212"
#RUN export ip_server1=147.135.153.118
RUN sed -i 's/\/\/\example.net\//http:\/\/$IP_SERVER\//' ./config/environment.js && \
    sed -i 's/example.net/http:\/\/$IP_SERVER\//' ./config/environment.js && \
    cat ./config/environment.js

#copy initial script
EXPOSE 8080 80 39573 22 6379 68 31140
#CMD [ "$HOME/startallskiff.sh","start" ]
COPY ./startallskiff.sh /startallskiff.sh
RUN chmod 777 /startallskiff.sh
RUN ls -la /
ENTRYPOINT [ "/startallskiff.sh" ]
#CMD ["nginx", "-g", "daemon off;"]
#CMD ["nginx","start"]
RUN apt install nano
CMD ["nginx", "-g", "daemon off;"]