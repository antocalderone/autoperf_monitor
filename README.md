# CarTrackerEvo

## Introduzione

CarTrackerEvo è un'applicazione mobile sviluppata in Flutter che trasforma il tuo smartphone in un potente strumento di monitoraggio per la tua auto. L'app registra in tempo reale le performance di guida, tiene traccia dei consumi di carburante, gestisce la manutenzione e offre un'esperienza personalizzabile.

È lo strumento ideale per gli appassionati di auto che desiderano avere sempre sotto controllo ogni aspetto del proprio veicolo.

## Funzionalità Principali

-   **Cruscotto in Tempo Reale:**
    -   Visualizza la velocità attuale tramite un tachimetro analogico.
    -   Monitora metriche chiave come altitudine, velocità media, velocità massima/minima e distanza percorsa.
    -   Indicatore di precisione del segnale GPS.

-   **Registrazione delle Sessioni di Guida:**
    -   Avvia e ferma la registrazione delle tue sessioni di guida con un semplice tocco.
    -   Salvataggio automatico di ogni sessione nel database locale per analisi future.

-   **Cronologia e Statistiche Dettagliate:**
    -   Visualizza l'elenco di tutte le sessioni di guida registrate.
    -   Per ogni sessione, accedi a un riepilogo con durata, distanza, velocità media e un grafico interattivo che mostra l'andamento della velocità nel tempo.
    -   Esporta i dati delle sessioni in formato CSV o i record di carburante in PDF.
    -   Elimina singole sessioni o azzera l'intera cronologia.

-   **Gestione del Carburante:**
    -   Registra ogni rifornimento indicando data, importo, litri, chilometraggio e tipo di carburante.
    -   Visualizza statistiche aggregate sui consumi, come il consumo medio (km/l) e il costo per chilometro.
    -   Grafico dello storico dei consumi per monitorare l'efficienza nel tempo.

-   **Registro Manutenzione:**
    -   Tieni traccia di tutti gli interventi di manutenzione effettuati sul veicolo (cambio olio, freni, ecc.).
    -   Registra data, chilometraggio, tipo di intervento, descrizione e costo.

-   **Personalizzazione:**
    -   Accedi alla schermata delle impostazioni per personalizzare l'aspetto dell'app.
    -   Scegli tra diverse colorazioni per il tema principale.
    -   Attiva o disattiva la modalità scura (Dark Mode).

## Come si Usa

1.  **Cruscotto:** La schermata principale mostra il cruscotto. Premi il pulsante centrale a forma di "play" per avviare la registrazione di una nuova sessione di guida. Premerlo di nuovo per fermarla.
2.  **Navigazione:** Usa la barra di navigazione in basso per spostarti tra le sezioni principali:
    -   **Cruscotto:** Per il monitoraggio in tempo reale.
    -   **Rifornimento:** Per aggiungere un nuovo rifornimento e visualizzare le statistiche sui consumi.
    -   **Cronologia:** Per rivedere tutte le sessioni di guida salvate.
3.  **Impostazioni:** Dalla schermata del cruscotto, tocca l'icona a forma di ingranaggio in alto a destra per accedere alle impostazioni e personalizzare il tema.
4.  **Manutenzione:** Dalla schermata della cronologia, tocca l'icona a forma di chiave inglese per accedere al registro di manutenzione.

## Tecnologie Utilizzate

-   **Framework:** [Flutter](https://flutter.dev/)
-   **Linguaggio:** [Dart](https://dart.dev/)
-   **State Management:** [Provider](https://pub.dev/packages/provider)
-   **Database Locale:** [sqflite](https://pub.dev/packages/sqflite)
-   **Geolocalizzazione:** [geolocator](https://pub.dev/packages/geolocator)
-   **Grafici:** [fl_chart](https://pub.dev/packages/fl_chart)
-   **Preferenze Utente:** [shared_preferences](https://pub.dev/packages/shared_preferences)
-   **Esportazione Dati:**
    -   [csv](https://pub.dev/packages/csv) per l'esportazione in CSV.
    -   [pdf](https://pub.dev/packages/pdf) per la generazione di PDF.
-   **Formattazione:** [intl](https://pub.dev/packages/intl)
