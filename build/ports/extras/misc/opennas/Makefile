PORTNAME=		opennas
PORTVERSION=	@@PROJECT_VERSION
PORTREVISION=	@@PROJECT_REVISION
CATEGORIES=		misc

MAINTAINER=		opennas@factorfx.com
COMMENT=		Storage appliance

BUILD_DEPENDS=	nginx:${PORTSDIR}/www/nginx-devel \
				nano:${PORTSDIR}/editors/nano \
				zsh:${PORTSDIR}/shells/zsh \
				ksh:${PORTSDIR}/shells/pdksh \
				tmux:${PORTSDIR}/sysutils/tmux \
				beadm:${PORTSDIR}/sysutils/beadm

RUN_DEPENDS:=	${BUILD_DEPENDS}

USE_PHP=		pcre ctype dom iconv json mbstring pdo pdo_sqlite phar posix session sqlite3 xml tokenizer simplexml apc intl openssl filter

USE_GITHUB=		yes
GH_ACCOUNT=		factorfx
GH_PROJECT=		OpenNAS2-port
GH_TAGNAME=		${PORTVERSION}_${PORTREVISION}
WRKSRC?=		${WRKDIR}/${GH_ACCOUNT}-${GH_PROJECT}-${GH_TAGNAME}

NO_BUILD=		yes

post-extract:
	mv ${WRKDIR}/${GH_ACCOUNT}-${GH_PROJECT}-* ${WRKSRC}

pre-install:
	${MKDIR} ${STAGEDIR}/var/log/nginx
	${MKDIR} ${STAGEDIR}${ETCDIR}/nginx
	${MKDIR} ${STAGEDIR}${ETCDIR}/php
	${MKDIR} ${STAGEDIR}${WWWDIR}

do-install:
	# nginx
	${INSTALL_DATA} ${WRKSRC}/nginx/nginx.conf ${STAGEDIR}${ETCDIR}/nginx

	# php
	${INSTALL_DATA} ${WRKSRC}/php/php-fpm.conf ${STAGEDIR}${ETCDIR}/php
	${INSTALL_DATA} ${WRKSRC}/php/php.ini ${STAGEDIR}${ETCDIR}/php

	# www
	${CP} -R ${WRKSRC}/www/ ${STAGEDIR}${WWWDIR}

.include <bsd.port.mk>
