String normalizeArabic(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x064B && r <= 0x065F) continue;
    if (r >= 0x0610 && r <= 0x061A) continue;
    if (r >= 0x06D6 && r <= 0x06E8) continue;
    if (r >= 0x06EA && r <= 0x06ED) continue;
    if (r >= 0x08D0 && r <= 0x08FF) continue;
    if (r >= 0xFE70 && r <= 0xFEFF) continue;
    if (r == 0x0622 || r == 0x0623 || r == 0x0625 || r == 0x0671) {
      buf.writeCharCode(0x0627); continue;
    }
    if (r == 0x0649) { buf.writeCharCode(0x064A); continue; }
    if (r == 0x0629) { buf.writeCharCode(0x0647); continue; }
    if (r == 0x0624) { buf.writeCharCode(0x0648); continue; }
    if (r == 0x0626) { buf.writeCharCode(0x064A); continue; }
    if (r == 0x0670) continue;
    if (r == 0x0640) continue;
    buf.writeCharCode(r);
  }
  return buf.toString();
}
