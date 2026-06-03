# Puck Mikrofon

Ett system för att spela in och lyssna på platsbundna anekdoter i Stockholm. Består av en fysisk Arduino-enhet och en SwiftUI-app för iOS.

## Fysisk prototyp (Arduino UNO)
- Tryck en gång för att starta inspelning — röd LED tänds och buzzer piper
- Tryck igen för att stoppa — röd LED släcks och buzzer ger lägre ton
- Komponenter: Arduino UNO, KY-038 mikrofon, tryckknapp, röd LED, buzzer

## Digital prototyp (SwiftUI / iOS)

### Views
**MapHomeView** — huvudskärmen med karta över Stockholm, röda pins och filter (Dagliga/Viktiga)

**AnecdoteListView** — vertikal lista med anekdoter kopplade till en specifik plats

**PlaybackView** — uppspelningsvy med waveform-animation och AI-röst via ElevenLabs

**ShareAnecdoteView** — visar QR-kod för att dela en anekdot med någon i närheten

**LocationPickerView** — karta där användaren väljer plats för en ny anekdot

**InfoView** — informationsskärm om appen och projektet

**ContentView** — appens startvy

### Services
**ElevenLabsService** — hanterar AI-genererad röstuppspelning via ElevenLabs API

**BebyggelseService** — hämtar historisk data från Svenska Wikipedia för 7 Stockholmsplatser

**LocationService** — hanterar GPS och användarens position

**AudioPlayer** — hanterar uppspelning av inspelade ljudfiler

**AudioRecorder** — hanterar ljudinspelning via mikrofon

### Models
**Anecdote** — datamodell för en anekdot med titel, beskrivning, plats och kategori

**AnecdoteStore** — hanterar lagring och filtrering av anekdoter via UserDefaults

**ButtonStyles** — återanvändbara UI-komponenter för knappar

## Kursprojekt
Proto II VT2026 — DSV, Stockholms universitet
