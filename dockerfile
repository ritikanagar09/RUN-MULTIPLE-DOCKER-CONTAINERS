FROM ubuntu

WORKDIR /aestest

COPY . /aestest
ENTRYPOINT ["tail", "-f", "/dev/null"]
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        build-essential \
        vim \
	libssl-dev
RUN gcc main1464.c -lcrypto -o main1464  
RUN gcc main1464ccm.c -lcrypto -o main1464ccm



