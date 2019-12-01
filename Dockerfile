FROM docker:19.03.2 as runtime
LABEL "repository"="https://github.com/MirzaMerdovic/Publish-Docker-Github-Action"
LABEL "maintainer"="Mirza Merdovic"

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as testEnv
RUN apk add coreutils bats ncurses

ADD test.bats /test.bats
ADD mock.sh /usr/local/bin/docker
ADD mock.sh /usr/bin/date

RUN /test.bats

FROM runtime