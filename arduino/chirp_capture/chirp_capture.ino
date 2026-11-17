// ELP311 - Chirp Modulation Demo
// ISD1820 PLAYE → D2 | HW-484 AO → A0

const int  PLAYE_PIN       = 2;
const int  MIC_PIN         = A0;
const int  NUM_SAMPLES     = 512;
const long SAMPLING_FREQ   = 4761;
const long SAMPLE_INTERVAL = 1000000L / SAMPLING_FREQ;
const int  TRIGGER_PULSE_US = 100;
const long PRE_DELAY_MS    = 100;
const long REPEAT_DELAY_MS = 3000;

int samples[NUM_SAMPLES];

void setup() {
  Serial.begin(115200);
  pinMode(PLAYE_PIN, OUTPUT);
  digitalWrite(PLAYE_PIN, LOW);
  Serial.println(F("=== ELP311 Chirp Demo ==="));
  Serial.println(F("Format: timestamp_us,adc_value"));
  delay(1000);
}

void fireAndCapture() {
  // Trigger ISD1820
  digitalWrite(PLAYE_PIN, LOW);
  delay(50);
  digitalWrite(PLAYE_PIN, HIGH);
  delayMicroseconds(TRIGGER_PULSE_US);
  digitalWrite(PLAYE_PIN, LOW);

  // Wait for ISD1820 to start playing
  delay(PRE_DELAY_MS);

  // Sample received signal
  long t0 = micros();
  for (int i = 0; i < NUM_SAMPLES; i++) {
    long target = t0 + (long)i * SAMPLE_INTERVAL;
    while (micros() < target);
    samples[i] = analogRead(MIC_PIN);
  }
}

void streamData() {
  Serial.println(F("--- CHIRP START ---"));
  for (int i = 0; i < NUM_SAMPLES; i++) {
    Serial.print((long)i * SAMPLE_INTERVAL);
    Serial.print(',');
    Serial.println(samples[i]);
  }
  Serial.println(F("--- CHIRP END ---"));
}

void printStats() {
  long sum  = 0;
  int vmin  = 1023, vmax = 0;
  for (int i = 0; i < NUM_SAMPLES; i++) {
    sum += samples[i];
    if (samples[i] < vmin) vmin = samples[i];
    if (samples[i] > vmax) vmax = samples[i];
  }
  Serial.print(F("Mean ADC: "));      Serial.println((float)sum / NUM_SAMPLES, 1);
  Serial.print(F("Peak-to-peak: "));  Serial.println(vmax - vmin);
  Serial.print(F("Max: "));           Serial.print(vmax);
  Serial.print(F("  Min: "));         Serial.println(vmin);
}

void loop() {
  fireAndCapture();
  streamData();
  printStats();
  delay(REPEAT_DELAY_MS);
}
