/* Stub sys/sdt.h for builds without systemtap */
#ifndef _SYS_SDT_H
#define _SYS_SDT_H

#define DTRACE_PROBE(provider, probe) do {} while(0)
#define DTRACE_PROBE1(provider, probe, a1) do {} while(0)
#define DTRACE_PROBE2(provider, probe, a1, a2) do {} while(0)
#define DTRACE_PROBE3(provider, probe, a1, a2, a3) do {} while(0)
#define DTRACE_PROBE4(provider, probe, a1, a2, a3, a4) do {} while(0)

#define STAP_PROBEV(provider, probe, ...) do {} while(0)

#endif /* _SYS_SDT_H */
