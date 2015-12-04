####################################################################################
#                Socket-daemon                                                     #
#                                                                                  #
#    Copyright (C) 2012-2015 Institut National de Recherche en Informatique        #
#    et en Automatique. All rights reserved.                                       #
#                                                                                  #
#    This program is free software; you can redistribute it and/or modify          #
#    it under the terms of the GNU Lesser General Public License version           #
#    3 as published by the Free Software Foundation.                               #
#                                                                                  #
#    This program is distributed in the hope that it will be useful,               #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of                #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                 #
#    GNU Library General Public License for more details.                          #
#                                                                                  #
#    You should have received a copy of the GNU Lesser General Public              #
#    License along with this program; if not, write to the Free Software           #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                      #
#    02111-1307  USA                                                               #
#                                                                                  #
#    Contact: Maxence.Guesdon@inria.fr                                             #
#                                                                                  #
#                                                                                  #
####################################################################################

# DO NOT FORGET TO UPDATE META FILE
VERSION=0.1.0

OCAMLFIND=ocamlfind
PACKAGES=lwt.unix,lwt.ppx
COMPFLAGS=-annot -safe-string -g
OCAMLPP=
OCAMLLIB:=`$(OCAMLC) -where`

INSTALLDIR=$(OCAMLLIB)

RM=rm -f
CP=cp -f
MKDIR=mkdir -p

LIB_SERVER=socket_daemon_server.cmxa
LIB_SERVER_CMXS=$(LIB_SERVER:.cmxa=.cmxs)
LIB_SERVER_A=$(LIB_SERVER:.cmxa=.a)
LIB_SERVER_BYTE=$(LIB_SERVER:.cmxa=.cma)
LIB_SERVER_CMI=$(LIB_SERVER:.cmxa=.cmi)

LIB_SERVER_CMXFILES= \
	sdaemon_common.cmx \
	sdaemon_server.cmx
LIB_SERVER_CMOFILES=$(LIB_SERVER_CMXFILES:.cmx=.cmo)
LIB_SERVER_CMIFILES=$(LIB_SERVER_CMXFILES:.cmx=.cmi)
LIB_SERVER_OFILES=$(LIB_SERVER_CMXFILES:.cmx=.o)

LIB_CLIENT=socket_daemon_client.cmxa
LIB_CLIENT_CMXS=$(LIB_CLIENT:.cmxa=.cmxs)
LIB_CLIENT_A=$(LIB_CLIENT:.cmxa=.a)
LIB_CLIENT_BYTE=$(LIB_CLIENT:.cmxa=.cma)
LIB_CLIENT_CMI=$(LIB_CLIENT:.cmxa=.cmi)

LIB_CLIENT_CMXFILES= \
	sdaemon_common.cmx \
	sdaemon_client.cmx
LIB_CLIENT_CMOFILES=$(LIB_CLIENT_CMXFILES:.cmx=.cmo)
LIB_CLIENT_CMIFILES=$(LIB_CLIENT_CMXFILES:.cmx=.cmi)
LIB_CLIENT_OFILES=$(LIB_CLIENT_CMXFILES:.cmx=.o)


all: byte opt
byte: $(LIB_SERVER_BYTE) $(LIB_CLIENT_BYTE)
opt: $(LIB_SERVER) $(LIB_CLIENT)

$(LIB_SERVER): $(LIB_SERVER_CMIFILES) $(LIB_SERVER_CMXFILES)
	$(OCAMLFIND) ocamlopt -o $@ -a -package $(PACKAGES) $(LIB_SERVER_CMXFILES)

$(LIB_SERVER_CMXS): $(LIB_SERVER_CMIFILES) $(LIB_SERVER_CMXFILES)
	$(OCAMLFIND) ocamlopt -shared -o $@ -package $(PACKAGES) $(LIB_SERVER_CMXFILES)

$(LIB_SERVER_BYTE): $(LIB_SERVER_CMIFILES) $(LIB_SERVER_CMOFILES)
	$(OCAMLFIND) ocamlc -o $@ -a -package $(PACKAGES) $(LIB_SERVER_CMOFILES)

$(LIB_CLIENT): $(LIB_CLIENT_CMIFILES) $(LIB_CLIENT_CMXFILES)
	$(OCAMLFIND) ocamlopt -o $@ -a -package $(PACKAGES) $(LIB_CLIENT_CMXFILES)

$(LIB_CLIENT_CMXS): $(LIB_CLIENT_CMIFILES) $(LIB_CLIENT_CMXFILES)
	$(OCAMLFIND) ocamlopt -shared -o $@ -package $(PACKAGES) $(LIB_CLIENT_CMXFILES)

$(LIB_CLIENT_BYTE): $(LIB_CLIENT_CMIFILES) $(LIB_CLIENT_CMOFILES)
	$(OCAMLFIND) ocamlc -o $@ -a -package $(PACKAGES) $(LIB_CLIENT_CMOFILES)


%.cmx: %.ml %.cmi
	$(OCAMLFIND) ocamlopt -c -package $(PACKAGES) $(COMPFLAGS) $<

%.cmo: %.ml %.cmi
	$(OCAMLFIND) ocamlc -c -package $(PACKAGES) $(COMPFLAGS) $<

%.cmi: %.mli
	$(OCAMLFIND) ocamlc -c -package $(PACKAGES) $(COMPFLAGS) $<

##########
.PHONY: doc
dump.odoc:
	$(OCAMLFIND) ocamldoc -package $(JS_PACKAGES) -dump $@ -rectypes \
	sdaemon_*.mli

doc: dump.odoc
	$(MKDIR) doc
	$(OCAMLFIND) ocamldoc -load $^ -t Socket-daemon -d doc -html

docstog: dump.odoc
	$(MKDIR) web/refdoc
	ocamldoc.opt \
	-t "Socket daemon reference documentation" \
	-load $^ -d web/refdoc -i `ocamlfind query stog` -g odoc_stog.cmxs

##########
install: all
	$(OCAMLFIND) install socket-daemon META LICENSE \
		$(LIB_SERVER) $(LIB_SERVER_CMXS) $(LIB_SERVER_OFILES) $(LIB_SERVER_CMXFILES) $(LIB_SERVER_A) \
		$(LIB_SERVER_BYTE) $(LIB_SERVER_CMIFILES) \
		$(LIB_CLIENT) $(LIB_CLIENT_CMXS) $(LIB_CLIENT_OFILES) $(LIB_CLIENT_CMXFILES) $(LIB_CLIENT_A) \
		$(LIB_CLIENT_BYTE) $(LIB_CLIENT_CMIFILES) $(LIB_CLIENT_CMIFILES:.cmi=.mli)

uninstall:
	ocamlfind remove socket-daemon

# archive :
###########
archive:
	git archive --prefix=socket-daemon-$(VERSION)/ HEAD | gzip > ../socket-daemon-gh-pages/socket-daemon-$(VERSION).tar.gz

#####
clean:
	$(RM) *.cm* *.o *.annot *.a dump.odoc

# headers :
###########
HEADFILES=Makefile *.ml *.mli
.PHONY: headers noheaders
headers:
	headache -h header -c .headache_config $(HEADFILES)

noheaders:
	headache -r -c .headache_config $(HEADFILES)

# depend :
##########

.PHONY: depend

.depend depend:
	$(OCAMLFIND) ocamldep `ls sdaemon*.ml sdaemon*.mli` > .depend

include .depend
