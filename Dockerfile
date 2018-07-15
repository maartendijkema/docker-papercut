FROM ubuntu
LABEL maintainer="Andrew Ying <hi@andrewying.com>"
LABEL description="PaperCut NG Server"

RUN useradd -mUd /papercut -s /bin/bash papercut
WORKDIR /papercut

RUN mkdir -p /papercut/server/data \
    && chown -R papercut:papercut /papercut
VOLUME /papercut/server

EXPOSE 9163 9191 9192 9193
RUN apt-get update \
    && apt-get install -y \
       cpio \
       cups \
       cups-daemon \
       curl \
       samba \
       wget \
       net-tools \
       iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /installer
RUN wget -O /installer/pcng-setup.sh $(curl https://www.papercut.com/products/ng/upgrade/ | grep https | grep -v link_previous | cut -d'"' -f2 | grep -Ei "pcng-setup-[0-9\.]+-linux-x64\.sh" | awk '{sub(/^.*\?http=/, "", $1)}{sub(/\.sh.*?$/, ".sh", $1)}{print $1}' | sed -e's/%\([0-9A-F][0-9A-F]\)/\\\\\x\1/g' | xargs echo -e) \
    && chmod 755 /installer/pcng-setup.sh
RUN cd /installer \
    && bash pcng-setup.sh -e \
    && cd papercut \
    && mv LICENCE.TXT PAPERCUT-NG-LICENCE.TXT \
    && sed -i 's/answered=/answered=1/' install \
    && sed -i 's/manual=/manual=1/' install \
    && sed -i 's/read reply/#read reply/g' install
RUN runuser -l papercut -c "cd /installer/papercut && bash install" \
    && cd /papercut \
    && bash MUST-RUN-AS-ROOT

ENV PC_MOBILITY_PRINT 1.0.1841
RUN wget -O /installer/pc-mobility-print.sh $(curl https://www.papercut.com/products/ng/mobility-print/download/server/ | grep https | grep -v link_previous | cut -d"'" -f2 | grep -Ei "pc-mobility-print-[0-9\.]+\.sh" | awk '{sub(/^.*\?http=/, "", $1)}{sub(/\.sh.*?$/, ".sh", $1)}{print $1}' | sed -e's/%\([0-9A-F][0-9A-F]\)/\\\\\x\1/g' | xargs echo -e) \
    && chmod 755 /installer/pc-mobility-print.sh
RUN mkdir /installer/mobility-print \
    && dd if="/installer/pc-mobility-print.sh" bs=4096 skip=1 | gunzip | (cd "/installer/mobility-print"; tar xfP -) \
    && mv -f /tmp/mobilitytemp/* /installer/mobility-print/
RUN cd /installer/mobility-print \
    && mv LICENCE.TXT PAPERCUT-LICENSE.TXT \
    && sed -i 's/interactive=true/interactive=false/' install \
    && sed -i 's/answered=/answered=1/' install \
    && sed -i 's/manual=/manual=1/' install
RUN runuser -l papercut -c "cd /installer/mobility-print && bash install" \
    && cd /papercut/pc-mobility-print \
    && bash MUST-RUN-AS-ROOT

COPY run.sh /papercut/run.sh
RUN chmod +x run.sh


ENTRYPOINT ["/papercut/run.sh"]
