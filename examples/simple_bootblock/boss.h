
void BossIO(__reg("d7") short int trap)="\ttrap #1\n";

void BossPutc(__reg("d0") short int c)=" move.l d7,-(sp)\n moveq #1,d7\n trap #1\n move.l (sp)+,d7";
void BossWrite(__reg("a0") const char *s)=" move.l d7,-(sp)\n moveq #2,d7\n trap #1\n move.l (sp)+,d7";
void BossWriteln(__reg("a0") const char *s)=" move.l d7,-(sp)\n moveq #3,d7\n trap #1\n move.l (sp)+,d7";
void BossPrintHex(__reg("d0") unsigned long l)=" move.l d7,-(sp)\n moveq #7,d7\n trap #1\n move.l (sp)+,d7";

void *BossManifestLoad(__reg("d0") unsigned long id)=" move.l d7,-(sp)\n moveq #22,d7\n trap #1\n move.l (sp)+,d7";


__reg("a0") void *BossMemAlloc(__reg("d0") unsigned long size)=" move.l d7,-(sp)\n moveq #2,d7\n trap #15\n move.l (sp)+,d7";
void BossMemFree(__reg("a0") void *mem)=" move.l d7,-(sp)\n moveq #3,d7\n trap #15\n move.l (sp)+,d7";
