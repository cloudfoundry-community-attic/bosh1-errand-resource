FROM concourse/busyboxplus:ruby

ADD gems /tmp/gems

RUN gem install /tmp/gems/*.gem --no-document && \
    gem install bosh_cli -v 1.2915.0 --no-document

ADD . /tmp/resource-gem

RUN cd /tmp/resource-gem && \
    gem build *.gemspec && gem install *.gem --no-document && \
    mkdir -p /opt/resource && \
    ln -s $(which ber_check) /opt/resource/check && \
    ln -s $(which ber_in) /opt/resource/in && \
    ln -s $(which ber_out) /opt/resource/out

