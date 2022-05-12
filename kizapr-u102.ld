MEMORY {
  ROM: start = $8000, size = $8000, file = %O, fill = yes;
}
SEGMENTS {
  CODE:         load = ROM, TYPE = ro;
}
