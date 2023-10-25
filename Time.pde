
float dt; // Delta time (clamped, for gameplay)
float dt_actual; // Delta time (raw, for fps display)
int lastMS; // The millisecond of the last frame

float CONST_MAX_DT = 0.1; // 100 ms

void updateTime()
{
  int mil = millis();
  dt_actual = (mil - lastMS) / 1000f;
  lastMS = mil;
  dt = min(dt_actual, CONST_MAX_DT);
}
