### R-Skript: SBB-OAI-Schnittstellen Request, Antwort, Herunterladen der Daten ###

# Dieses Tutorial bietet Beispiele für Abfragen über die OAI-Schnittstelle mit RStudio. 
# Es behandelt exemplarische Anfragen an die OAI-PMH-Schnittstelle der Staatsbibliothek zu Berlin - PK.


## Einrichten der Arbeitsumgebung ##

# Zuallererst sollten Sie das Arbeitsverzeichnis, in dem Sie die im Verlauf dieses Tutorials
# anfallenden Dateien speichern, festlegen. Dafür können Sie mit getwd() herausfinden, wo RStudio 
# Ihre Dateien speichern würde, und dies gegebenenfalls mit setwd() ändern. 
getwd()
setwd("pfad/zu/meinem/arbeitsverzeichnis")

# Danach wird die Arbeitsumgebung eingerichtet, indem die benötigten Bibliotheken installiert werden.
install.packages("oai")
install.packages("stringr")
install.packages("jsonlite")

# Um die installierten Bibliotheken zu verwenden, rufen Sie diese bitte nun ab, 
# damit RStudio auf den darin enthaltenen Code zurückgreifen kann.
library(oai)
library(stringr)
library(jsonlite)


## Abfrage der OAI-Schnittstelle ##

# Im ersten Schritt betrachten wir nun einmal die grundlegenden Informationen der 
# OAI-PMH-Schnittstelle der Staatsbibliothek zu Berlin – PK, dafür wird der 
# Befehl identify id() und die Basis-URL der OAI-Schnittstelle (https://oai.sbb.berlin) genutzt.
id("https://oai.sbb.berlin/")

#   repositoryName                DC MOAI 
#   baseURL                       https://oai.sbb.berlin/ 
#   protocolVersion               2.0 
#   adminEmail                    developers@sbb.spk-berlin.de
#	  earliestDatestamp             2010-07-22T18:10:16Z
#  	deletedRecord                 transient
#   granularity                   YYYY-MM-DDThh:mm:ssZ 
#   description                   oaidigital.staatsbibliothek-berlin.de:oai:digital.staatsbibliothek-berlin.de:PPN123456789

## Abfrage aller Datensets ##

# Im nächsten Schritt werden alle verfügbaren Datensets mit der Funktion 
# list_sets abgefragt und angezeigt.
list_sets("https://oai.sbb.berlin/?verb=ListSets")

# Um die Abfrageergebnisse leichter lesbar darzustellen, nutzen Sie den 
# nachfolgenden Code, der die Ergebnisse in tabellarischer Form präsentiert.
SBB_Sets <- list_sets("https://oai.sbb.berlin/?verb=ListSets")
View(SBB_Sets)

# Um herauszufinden, in welche Metadatenformate die OAI-Schnittstelle Datensätze ausgibt, 
# können wir folgenden Code verwenden.
Metadata <- list_metadataformats(url = "https://oai.sbb.berlin/")
View(Metadata)

# Darüber hinaus können wir uns anzeigen lassen, wie viele Datensätze 
# in dem jeweiligen Metadatenformat vorhanden sind.
count_identifiers(url = "https://oai.sbb.berlin/metadataPrefix=mets")
# Insgesamt = 216.854 mets Datensätze
count_identifiers(url = "https://oai.sbb.berlin/metadataPrefix=oai_dc")
# Insgesamt = 216.854 oai Datensätze

# In den folgenden Beispielen betrachten wir nun das Set "Illustrierte Liedflugschriften". 
# Zuerst schauen wir uns an, wie viele Datensätze dieses Set enthält.
count_identifiers(url = "https://oai.sbb.berlin/?verb=ListIdentifiers&set=illustrierte.liedflugschriften", 
                  prefix = "oai_dc")
# Insgesamt = 1589 Datensätze

# Darauf aufbauend betrachten wir alle Datensätze und lassen uns diese 
# zur besseren Lesbarkeit in Form einer Tabelle ausgeben.
record_list <- list_records("https://oai.sbb.berlin/", 
                            metadataPrefix="oai_dc", 
                            set="illustrierte.liedflugschriften")
# Betrachten der Tabelle
View(record_list)

## Ausgabe von Titeln und Autoren eines Sets ##

# Haben Sie nun beschlossen, dass für Sie vor allem die Autoren und Titel 
# der Liedflugschriften wichtig sind, können Sie sich diese mit folgendem Code 
# ausgeben lassen. Beachten Sie bitte, dass die Ausgabe der Antworten 
# hier auf 10 beschränkt wurde. Sollten Sie mehr Antworten ausgeben lassen wollen, 
# ändern Sie bitte die Zahl in den Klammern.
head(record_list$title, 10)
head(record_list$creator, 10)
# In den Antworten sehen Sie die Angabe "NA", dies steht für "not available", 
# also nicht verfügbar. Das bedeutet, dass nicht zu jedem Liedflugblatt ein Autor bekannt ist.

## Ausgabe der Links zu den Objekten ##
# Für den nachfolgenden Code benötigen wir eine weitere Bibliothek, 
# weswegen wir diese nun installieren und ausführen.
install.packages("dplyr")
library(dplyr)

# Im folgenden Code werden die Links zu den digitalisierten Objekten ausgegeben. 
# Diese müssen wir manuell erstellen, indem wir die OAI-Adresse durch den Link 
# zur Werkansicht ersetzen.
record_list$Werkansicht <- record_list$identifier
record_list %>% 
  mutate(Werkansicht = str_replace_all(Werkansicht, "oai:digital.staatsbibliothek-berlin.de:", "https://digital.staatsbibliothek-berlin.de/werkansicht?ppn=")) -> record_list

# Nun lassen wir uns die ersten 10 Links zu den digitalisierten Objekten ausgeben.
# Sollten Sie mehr Links ausgeben lassen wollen, ändern Sie einfach die entsprechende 
# Zahl in der Klammer.
head(record_list$Werkansicht, 10)

## Herunterladen der Daten als CSV-Datei und im JSON-Format ##

# Gehen wir nun davon aus, dass Sie die folgenden Metadaten für die Weiterverwendung benötigen:
# date, coverage, publisher und creator. Exemplarisch werden wir diese für alle 1589 Objekte 
# im Set "Illustrierte Liedflugschriften" in eine Tabelle einbinden.
my_metadata <- select(record_list, date, coverage, publisher, creator)
View(my_metadata)
# Diese Tabelle legen wir nun als CSV-Datei im Arbeitsordner ab.
write.csv(my_metadata, file = "my_metadata_liedflugschriften.csv", fileEncoding = "UTF-8", row.names = F, na = "") 

# Möchten Sie die Datei mit allen Metadaten als CSV-Datei speichern, 
# nutzen Sie bitte den nachfolgenden Code.
write.csv(record_list, file = "record_list_liedflugschriften.csv", fileEncoding = "UTF-8", row.names = F, na = "") 

# Möchten Sie jedoch die Datensätze im OAI-DC-Metadatenformat abfragen 
# und als JSON-Datei speichern, können Sie folgenden Code verwenden.
record_data_oai_dc_xml <- get_records(ids = record_list$identifier, 
                                      url="https://oai.sbb.berlin/", 
                                      prefix="oai_dc", 
                                      as = "parsed")  


json_obj_dc = toJSON(record_data_oai_dc_xml, pretty=TRUE, auto_unbox=TRUE)
write(json_obj_dc, "illustrierte.liedflugschriften.oai_dc.json")

