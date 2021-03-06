#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include <exec/types.h>
#include "sprite_multiplexer.h"
#include "circallator.h"
#include "tools.h"
#include "introduction.barebone.h"
#include "evoke2019.h"
#include "textmonochrome.h"
#include "credits.barebone.h"

#define MAX_NUM_SPRITE_REUSE 24
#define NUMBER_of_SOBS 39
#define SPRITE_HEIGHT 10

struct HypotrochoidsEtAl {
  unsigned int table_length;
  unsigned short *pos_table;
};

static const char *hypotrochoid_text[] = {
  "S.O.B.s",
  "~~~~~~~",
  "",
  "Sprite OBjects",
  "",
  "Or: The sounds I made...",
  "    while programming..."
};

static unsigned short hypotrochoid_pos_table0[] = {
0xC797, 0xC897, 0xC998, 0xCA99, 0xCB9A, 0xCC9A, 0xCD9B, 0xCE9B, 0xCF9B, 0xCF9B, 0xD09B, 0xD19B, 
0xD19B, 0xD19B, 0xD29B, 0xD29B, 0xD29B, 0xD29B, 0xD19A, 0xD19A, 0xD09A, 0xD09A, 0xCF9A, 0xCE99, 
0xCD99, 0xCC99, 0xCB99, 0xCA9A, 0xC89A, 0xC79A, 0xC69B, 0xC49B, 0xC39C, 0xC19C, 0xBF9D, 0xBE9E, 
0xBC9F, 0xBAA0, 0xB9A1, 0xB7A2, 0xB6A4, 0xB4A5, 0xB3A7, 0xB1A8, 0xB0AA, 0xAEAC, 0xADAD, 0xACAF, 
0xABB1, 0xAAB3, 0xA9B5, 0xA8B7, 0xA8B9, 0xA7BB, 0xA6BD, 0xA6BE, 0xA6C0, 0xA6C2, 0xA5C4, 0xA5C5, 
0xA5C7, 0xA5C8, 0xA6CA, 0xA6CB, 0xA6CC, 0xA6CE, 0xA7CE, 0xA7CF, 0xA7D0, 0xA8D1, 0xA8D1, 0xA8D2, 
0xA9D2, 0xA9D2, 0xA9D2, 0xAAD2, 0xAAD2, 0xAAD2, 0xAAD2, 0xAAD1, 0xA9D1, 0xA9D0, 0xA9CF, 0xA8CF, 
0xA8CE, 0xA7CD, 0xA6CC, 0xA5CC, 0xA4CB, 0xA3CA, 0xA2C9, 0xA0C8, 0x9FC7, 0x9DC7, 0x9CC6, 0x9AC5, 
0x98C5, 0x96C4, 0x94C4, 0x92C3, 0x90C3, 0x8EC3, 0x8CC3, 0x8AC3, 0x88C3, 0x86C3, 0x83C3, 0x81C4, 
0x7FC4, 0x7DC5, 0x7BC5, 0x79C6, 0x77C7, 0x75C8, 0x74C9, 0x72CA, 0x70CB, 0x6FCC, 0x6ECD, 0x6CCE, 
0x6BCF, 0x6AD0, 0x69D1, 0x68D2, 0x68D3, 0x67D4, 0x66D5, 0x66D6, 0x66D6, 0x65D7, 0x65D8, 0x65D8, 
0x65D9, 0x65D9, 0x65D9, 0x66D9, 0x66D9, 0x66D9, 0x66D9, 0x66D9, 0x67D8, 0x67D8, 0x67D7, 0x67D6, 
0x68D5, 0x68D4, 0x68D3, 0x68D2, 0x68D0, 0x67CF, 0x67CD, 0x67CC, 0x67CA, 0x66C9, 0x65C7, 0x65C5, 
0x64C4, 0x63C2, 0x62C0, 0x61BE, 0x60BD, 0x5FBB, 0x5DB9, 0x5CB8, 0x5AB6, 0x59B5, 0x57B3, 0x55B2, 
0x54B1, 0x52AF, 0x50AE, 0x4EAD, 0x4CAC, 0x4AAC, 0x49AB, 0x47AA, 0x45AA, 0x43A9, 0x42A9, 0x40A9, 
0x3EA9, 0x3DA9, 0x3CA9, 0x3AA9, 0x39A9, 0x38A9, 0x37A9, 0x36A9, 0x35AA, 0x34AA, 0x34AA, 0x33AB, 
0x33AB, 0x33AB, 0x33AB, 0x33AC, 0x33AC, 0x33AC, 0x33AC, 0x34AC, 0x34AC, 0x35AC, 0x36AB, 0x36AB, 
0x37AA, 0x38AA, 0x39A9, 0x3AA8, 0x3BA7, 0x3CA6, 0x3DA5, 0x3EA4, 0x3FA2, 0x40A1, 0x409F, 0x419E, 
0x429C, 0x439A, 0x4398, 0x4496, 0x4494, 0x4592, 0x4590, 0x458E, 0x458C, 0x468A, 0x4587, 0x4585, 
0x4583, 0x4581, 0x447F, 0x447D, 0x437B, 0x4379, 0x4277, 0x4175, 0x4074, 0x4072, 0x3F71, 0x3E6F, 
0x3D6E, 0x3C6D, 0x3B6C, 0x3A6B, 0x396A, 0x3869, 0x3769, 0x3668, 0x3668, 0x3567, 0x3467, 0x3467, 
0x3367, 0x3367, 0x3367, 0x3367, 0x3368, 0x3368, 0x3368, 0x3368, 0x3469, 0x3469, 0x3569, 0x366A, 
0x376A, 0x386A, 0x396A, 0x3A6A, 0x3C6A, 0x3D6A, 0x3E6A, 0x406A, 0x426A, 0x436A, 0x4569, 0x4769, 
0x4968, 0x4A67, 0x4C67, 0x4E66, 0x5065, 0x5264, 0x5462, 0x5561, 0x5760, 0x595E, 0x5A5D, 0x5C5B, 
0x5D5A, 0x5F58, 0x6056, 0x6155, 0x6253, 0x6351, 0x644F, 0x654E, 0x654C, 0x664A, 0x6749, 0x6747, 
0x6746, 0x6744, 0x6843, 0x6841, 0x6840, 0x683F, 0x683E, 0x673D, 0x673C, 0x673B, 0x673B, 0x663A, 
0x663A, 0x663A, 0x663A, 0x663A, 0x653A, 0x653A, 0x653A, 0x653B, 0x653B, 0x653C, 0x663D, 0x663D, 
0x663E, 0x673F, 0x6840, 0x6841, 0x6942, 0x6A43, 0x6B44, 0x6C45, 0x6E46, 0x6F47, 0x7048, 0x7249, 
0x744A, 0x754B, 0x774C, 0x794D, 0x7B4E, 0x7D4E, 0x7F4F, 0x814F, 0x8350, 0x8650, 0x8850, 0x8A50, 
0x8C50, 0x8E50, 0x9050, 0x9250, 0x944F, 0x964F, 0x984E, 0x9A4E, 0x9C4D, 0x9D4C, 0x9F4C, 0xA04B, 
0xA24A, 0xA349, 0xA448, 0xA547, 0xA647, 0xA746, 0xA845, 0xA844, 0xA944, 0xA943, 0xA942, 0xAA42, 
0xAA41, 0xAA41, 0xAA41, 0xAA41, 0xA941, 0xA941, 0xA941, 0xA841, 0xA842, 0xA842, 0xA743, 0xA744, 
0xA745, 0xA645, 0xA647, 0xA648, 0xA649, 0xA54B, 0xA54C, 0xA54E, 0xA54F, 0xA651, 0xA653, 0xA655, 
0xA656, 0xA758, 0xA85A, 0xA85C, 0xA95E, 0xAA60, 0xAB62, 0xAC64, 0xAD66, 0xAE67, 0xB069, 0xB16B, 
0xB36C, 0xB46E, 0xB66F, 0xB771, 0xB972, 0xBA73, 0xBC74, 0xBE75, 0xBF76, 0xC177, 0xC377, 0xC478, 
0xC678, 0xC779, 0xC879, 0xCA79, 0xCB7A, 0xCC7A, 0xCD7A, 0xCE7A, 0xCF79, 0xD079, 0xD079, 0xD179, 
0xD179, 0xD278, 0xD278, 0xD278, 0xD278, 0xD178, 0xD178, 0xD178, 0xD078, 0xCF78, 0xCF78, 0xCE78, 
0xCD78, 0xCC79, 0xCB79, 0xCA7A, 0xC97B, 0xC87C, 0xC67C, 0xC57E, 0xC47F, 0xC380, 0xC281, 0xC183, 
0xC084, 0xBE86, 0xBD88, 0xBC89, 0xBC8B, 0xBB8D, 0xBA8F, 0xB991, 0xB993, 0xB896, 0xB898, 0xB89A, 
0xB79C, 0xB79E, 0xB7A0, 0xB7A2, 0xB7A4, 0xB8A6, 0xB8A8, 0xB8AA, 0xB9AC, 0xB9AE, 0xBAAF, 0xBAB1, 
0xBBB2, 0xBCB4, 0xBCB5, 0xBDB6, 0xBEB7, 0xBFB8, 0xBFB9, 0xC0B9, 0xC1BA, 0xC1BA, 0xC2BB, 0xC2BB, 
0xC3BB, 0xC3BB, 0xC3BB, 0xC3BB, 0xC4BB, 0xC3BA, 0xC3BA, 0xC3BA, 0xC3B9, 0xC2B9, 0xC2B9, 0xC1B8, 
0xC0B8, 0xBFB7, 0xBEB7, 0xBDB6, 0xBCB6, 0xBAB6, 0xB9B6, 0xB7B5, 0xB5B5, 0xB4B5, 0xB2B5, 0xB0B5, 
0xAEB6, 0xACB6, 0xAAB6, 0xA8B7, 0xA6B7, 0xA4B8, 0xA2B9, 0xA0BA, 0x9EBB, 0x9DBC, 0x9BBD, 0x99BE, 
0x97BF, 0x95C1, 0x94C2, 0x92C3, 0x91C5, 0x90C6, 0x8EC8, 0x8DCA, 0x8CCB, 0x8BCD, 0x8ACE, 0x8AD0, 
0x89D1, 0x89D2, 0x88D4, 0x88D5, 0x88D6, 0x87D7, 0x87D8, 0x87D9, 0x87DA, 0x87DB, 0x87DC, 0x88DC, 
0x88DD, 0x88DD, 0x88DD, 0x88DD, 0x88DD, 0x89DD, 0x89DC, 0x89DC, 0x89DB, 0x89DB, 0x89DA, 0x89D9, 
0x88D8, 0x88D7, 0x88D6, 0x87D5, 0x87D4, 0x86D3, 0x85D1, 0x84D0, 0x83CF, 0x82CE, 0x81CC, 0x7FCB, 
0x7ECA, 0x7CC8, 0x7BC7, 0x79C6, 0x77C5, 0x76C4, 0x74C3, 0x72C2, 0x70C1, 0x6EC1, 0x6BC0, 0x69C0, 
0x67BF, 0x65BF, 0x63BE, 0x61BE, 0x5FBE, 0x5DBE, 0x5BBE, 0x59BF, 0x57BF, 0x56BF, 0x54C0, 0x52C0, 
0x51C0, 0x4FC1, 0x4EC2, 0x4DC2, 0x4CC3, 0x4BC3, 0x4AC4, 0x49C5, 0x49C5, 0x48C6, 0x48C6, 0x47C7, 
0x47C7, 0x47C8, 0x47C8, 0x47C8, 0x47C8, 0x48C8, 0x48C8, 0x48C8, 0x49C7, 0x49C7, 0x4AC6, 0x4AC6, 
0x4BC5, 0x4BC4, 0x4CC3, 0x4CC2, 0x4DC1, 0x4DBF, 0x4EBE, 0x4EBC, 0x4EBB, 0x4FB9, 0x4FB7, 0x4FB5, 
0x4FB3, 0x4FB1, 0x4EAF, 0x4EAD, 0x4EAB, 0x4DA9, 0x4DA7, 0x4CA5, 0x4BA3, 0x4BA1, 0x4A9F, 0x499D, 
0x489B, 0x469A, 0x4598, 0x4496, 0x4395, 0x4193, 0x4092, 0x3E90, 0x3D8F, 0x3C8E, 0x3A8D, 0x398C, 
0x378C, 0x368B, 0x358A, 0x338A, 0x3289, 0x3189, 0x3089, 0x2F89, 0x2E89, 0x2E89, 0x2D89, 0x2C89, 
0x2C89, 0x2C89, 0x2C89, 0x2C89, 0x2C8A, 0x2C8A, 0x2C8A, 0x2C8A, 0x2D8A, 0x2E8A, 0x2E8A, 0x2F8A, 
0x308A, 0x318A, 0x328A, 0x3389, 0x3589, 0x3688, 0x3787, 0x3987, 0x3A86, 0x3C85, 0x3D84, 0x3E83, 
0x4081, 0x4180, 0x437E, 0x447D, 0x457B, 0x4679, 0x4878, 0x4976, 0x4A74, 0x4B72, 0x4B70, 0x4C6E, 
0x4D6C, 0x4D6A, 0x4E68, 0x4E66, 0x4E64, 0x4F62, 0x4F60, 0x4F5E, 0x4F5C, 0x4F5A, 0x4E58, 0x4E57, 
0x4E55, 0x4D54, 0x4D52, 0x4C51, 0x4C50, 0x4B4F, 0x4B4E, 0x4A4D, 0x4A4D, 0x494C, 0x494C, 0x484B, 
0x484B, 0x484B, 0x474B, 0x474B, 0x474B, 0x474B, 0x474C, 0x474C, 0x484D, 0x484D, 0x494E, 0x494E, 
0x4A4F, 0x4B50, 0x4C50, 0x4D51, 0x4E51, 0x4F52, 0x5153, 0x5253, 0x5453, 0x5654, 0x5754, 0x5954, 
0x5B55, 0x5D55, 0x5F55, 0x6155, 0x6355, 0x6554, 0x6754, 0x6953, 0x6B53, 0x6E52, 0x7052, 0x7251, 
0x7450, 0x764F, 0x774E, 0x794D, 0x7B4C, 0x7C4B, 0x7E49, 0x7F48, 0x8147, 0x8245, 0x8344, 0x8443, 
0x8542, 0x8640, 0x873F, 0x873E, 0x883D, 0x883C, 0x883B, 0x893A, 0x8939, 0x8938, 0x8938, 0x8937, 
0x8937, 0x8936, 0x8836, 0x8836, 0x8836, 0x8836, 0x8836, 0x8837, 0x8737, 0x8738, 0x8739, 0x873A, 
0x873B, 0x873C, 0x883D, 0x883E, 0x883F, 0x8941, 0x8942, 0x8A43, 0x8A45, 0x8B46, 0x8C48, 0x8D49, 
0x8E4B, 0x904D, 0x914E, 0x9250, 0x9451, 0x9552, 0x9754, 0x9955, 0x9B56, 0x9C57, 0x9E58, 0xA059, 
0xA25A, 0xA45B, 0xA65C, 0xA85C, 0xAA5D, 0xAC5D, 0xAE5D, 0xB05E, 0xB25E, 0xB45E, 0xB55E, 0xB75E, 
0xB95D, 0xBA5D, 0xBC5D, 0xBD5D, 0xBE5C, 0xBF5C, 0xC05B, 0xC15B, 0xC25A, 0xC25A, 0xC35A, 0xC359, 
0xC359, 0xC359, 0xC458, 0xC358, 0xC358, 0xC358, 0xC358, 0xC258, 0xC258, 0xC159, 0xC159, 0xC05A, 
0xBF5A, 0xBF5B, 0xBE5C, 0xBD5D, 0xBC5E, 0xBC5F, 0xBB61, 0xBA62, 0xBA64, 0xB965, 0xB967, 0xB869, 
0xB86B, 0xB86D, 0xB76F, 0xB771, 0xB773, 0xB775, 0xB777, 0xB879, 0xB87B, 0xB87D, 0xB980, 0xB982, 
0xBA84, 0xBB86, 0xBC88, 0xBC8A, 0xBD8B, 0xBE8D, 0xC08F, 0xC190, 0xC292, 0xC393, 0xC494, 0xC595
};

static unsigned short lissajou_pos_table0[] = {
0x8A8C, 0x8B8C, 0x8D8D, 0x8E8E, 0x908F, 0x9190, 0x9391, 0x9492, 0x9693, 0x9894, 0x9995, 0x9B96, 
0x9C97, 0x9E98, 0x9F99, 0xA19A, 0xA29B, 0xA49C, 0xA59D, 0xA79E, 0xA89F, 0xA99F, 0xABA0, 0xACA1, 
0xAEA2, 0xAFA3, 0xB0A4, 0xB2A5, 0xB3A6, 0xB4A7, 0xB6A8, 0xB7A8, 0xB8A9, 0xB9AA, 0xBBAB, 0xBCAC, 
0xBDAD, 0xBEAE, 0xBFAE, 0xC0AF, 0xC1B0, 0xC2B1, 0xC3B2, 0xC4B2, 0xC5B3, 0xC6B4, 0xC7B5, 0xC8B6, 
0xC9B6, 0xCAB7, 0xCAB8, 0xCBB9, 0xCCB9, 0xCDBA, 0xCDBB, 0xCEBB, 0xCFBC, 0xCFBD, 0xD0BD, 0xD0BE, 
0xD1BF, 0xD1BF, 0xD2C0, 0xD2C1, 0xD3C1, 0xD3C2, 0xD3C2, 0xD3C3, 0xD4C4, 0xD4C4, 0xD4C5, 0xD4C5, 
0xD4C6, 0xD4C6, 0xD4C7, 0xD5C7, 0xD4C8, 0xD4C8, 0xD4C9, 0xD4C9, 0xD4CA, 0xD4CA, 0xD4CA, 0xD3CB, 
0xD3CB, 0xD3CB, 0xD3CC, 0xD2CC, 0xD2CD, 0xD1CD, 0xD1CD, 0xD0CD, 0xD0CE, 0xCFCE, 0xCFCE, 0xCECE, 
0xCDCF, 0xCDCF, 0xCCCF, 0xCBCF, 0xCACF, 0xCAD0, 0xC9D0, 0xC8D0, 0xC7D0, 0xC6D0, 0xC5D0, 0xC4D0, 
0xC3D0, 0xC2D0, 0xC1D0, 0xC0D0, 0xBFD0, 0xBED0, 0xBDD0, 0xBCD0, 0xBBD0, 0xB9D0, 0xB8D0, 0xB7D0, 
0xB6D0, 0xB4D0, 0xB3D0, 0xB2D0, 0xB0D0, 0xAFCF, 0xAECF, 0xACCF, 0xABCF, 0xA9CF, 0xA8CE, 0xA7CE, 
0xA5CE, 0xA4CE, 0xA2CD, 0xA1CD, 0x9FCD, 0x9ECD, 0x9CCC, 0x9BCC, 0x99CB, 0x98CB, 0x96CB, 0x94CA, 
0x93CA, 0x91CA, 0x90C9, 0x8EC9, 0x8DC8, 0x8BC8, 0x8AC7, 0x88C7, 0x86C6, 0x85C6, 0x83C5, 0x82C5, 
0x80C4, 0x7FC4, 0x7DC3, 0x7BC2, 0x7AC2, 0x78C1, 0x77C1, 0x75C0, 0x74BF, 0x72BF, 0x71BE, 0x6FBD, 
0x6EBD, 0x6CBC, 0x6BBB, 0x6ABB, 0x68BA, 0x67B9, 0x65B9, 0x64B8, 0x63B7, 0x61B6, 0x60B6, 0x5FB5, 
0x5DB4, 0x5CB3, 0x5BB2, 0x5AB2, 0x58B1, 0x57B0, 0x56AF, 0x55AE, 0x54AE, 0x53AD, 0x52AC, 0x51AB, 
0x50AA, 0x4FA9, 0x4EA8, 0x4DA8, 0x4CA7, 0x4BA6, 0x4AA5, 0x49A4, 0x49A3, 0x48A2, 0x47A1, 0x46A0, 
0x469F, 0x459F, 0x449E, 0x449D, 0x439C, 0x439B, 0x429A, 0x4299, 0x4198, 0x4197, 0x4096, 0x4095, 
0x4094, 0x4093, 0x3F92, 0x3F91, 0x3F90, 0x3F8F, 0x3F8E, 0x3F8D, 0x3F8C, 0x3F8C, 0x3F8B, 0x3F8A, 
0x3F89, 0x3F88, 0x3F87, 0x3F86, 0x3F85, 0x4084, 0x4083, 0x4082, 0x4081, 0x4180, 0x417F, 0x427E, 
0x427D, 0x437C, 0x437B, 0x447A, 0x4479, 0x4578, 0x4678, 0x4677, 0x4776, 0x4875, 0x4974, 0x4973, 
0x4A72, 0x4B71, 0x4C70, 0x4D6F, 0x4E6F, 0x4F6E, 0x506D, 0x516C, 0x526B, 0x536A, 0x5469, 0x5569, 
0x5668, 0x5767, 0x5866, 0x5A65, 0x5B65, 0x5C64, 0x5D63, 0x5F62, 0x6061, 0x6161, 0x6360, 0x645F, 
0x655E, 0x675E, 0x685D, 0x6A5C, 0x6B5C, 0x6C5B, 0x6E5A, 0x6F5A, 0x7159, 0x7258, 0x7458, 0x7557, 
0x7756, 0x7856, 0x7A55, 0x7B55, 0x7D54, 0x7F53, 0x8053, 0x8252, 0x8352, 0x8551, 0x8651, 0x8850, 
0x8950, 0x8B4F, 0x8D4F, 0x8E4E, 0x904E, 0x914D, 0x934D, 0x944D, 0x964C, 0x984C, 0x994C, 0x9B4B, 
0x9C4B, 0x9E4A, 0x9F4A, 0xA14A, 0xA24A, 0xA449, 0xA549, 0xA749, 0xA849, 0xA948, 0xAB48, 0xAC48, 
0xAE48, 0xAF48, 0xB047, 0xB247, 0xB347, 0xB447, 0xB647, 0xB747, 0xB847, 0xB947, 0xBB47, 0xBC47, 
0xBD47, 0xBE47, 0xBF47, 0xC047, 0xC147, 0xC247, 0xC347, 0xC447, 0xC547, 0xC647, 0xC747, 0xC847, 
0xC947, 0xCA47, 0xCA48, 0xCB48, 0xCC48, 0xCD48, 0xCD48, 0xCE49, 0xCF49, 0xCF49, 0xD049, 0xD04A, 
0xD14A, 0xD14A, 0xD24A, 0xD24B, 0xD34B, 0xD34C, 0xD34C, 0xD34C, 0xD44D, 0xD44D, 0xD44D, 0xD44E, 
0xD44E, 0xD44F, 0xD44F, 0xD550, 0xD450, 0xD451, 0xD451, 0xD452, 0xD452, 0xD453, 0xD453, 0xD354, 
0xD355, 0xD355, 0xD356, 0xD256, 0xD257, 0xD158, 0xD158, 0xD059, 0xD05A, 0xCF5A, 0xCF5B, 0xCE5C, 
0xCD5C, 0xCD5D, 0xCC5E, 0xCB5E, 0xCA5F, 0xCA60, 0xC961, 0xC861, 0xC762, 0xC663, 0xC564, 0xC465, 
0xC365, 0xC266, 0xC167, 0xC068, 0xBF69, 0xBE69, 0xBD6A, 0xBC6B, 0xBB6C, 0xB96D, 0xB86E, 0xB76F, 
0xB66F, 0xB470, 0xB371, 0xB272, 0xB073, 0xAF74, 0xAE75, 0xAC76, 0xAB77, 0xA978, 0xA878, 0xA779, 
0xA57A, 0xA47B, 0xA27C, 0xA17D, 0x9F7E, 0x9E7F, 0x9C80, 0x9B81, 0x9982, 0x9883, 0x9684, 0x9485, 
0x9386, 0x9187, 0x9088, 0x8E89, 0x8D8A, 0x8B8B, 0x8A8B, 0x888C, 0x868D, 0x858E, 0x838F, 0x8290, 
0x8091, 0x7F92, 0x7D93, 0x7B94, 0x7A95, 0x7896, 0x7797, 0x7598, 0x7499, 0x729A, 0x719B, 0x6F9C, 
0x6E9D, 0x6C9E, 0x6B9F, 0x6A9F, 0x68A0, 0x67A1, 0x65A2, 0x64A3, 0x63A4, 0x61A5, 0x60A6, 0x5FA7, 
0x5DA8, 0x5CA8, 0x5BA9, 0x5AAA, 0x58AB, 0x57AC, 0x56AD, 0x55AE, 0x54AE, 0x53AF, 0x52B0, 0x51B1, 
0x50B2, 0x4FB2, 0x4EB3, 0x4DB4, 0x4CB5, 0x4BB6, 0x4AB6, 0x49B7, 0x49B8, 0x48B9, 0x47B9, 0x46BA, 
0x46BB, 0x45BB, 0x44BC, 0x44BD, 0x43BD, 0x43BE, 0x42BF, 0x42BF, 0x41C0, 0x41C1, 0x40C1, 0x40C2, 
0x40C2, 0x40C3, 0x3FC4, 0x3FC4, 0x3FC5, 0x3FC5, 0x3FC6, 0x3FC6, 0x3FC7, 0x3FC7, 0x3FC8, 0x3FC8, 
0x3FC9, 0x3FC9, 0x3FCA, 0x3FCA, 0x3FCA, 0x40CB, 0x40CB, 0x40CB, 0x40CC, 0x41CC, 0x41CD, 0x42CD, 
0x42CD, 0x43CD, 0x43CE, 0x44CE, 0x44CE, 0x45CE, 0x46CF, 0x46CF, 0x47CF, 0x48CF, 0x49CF, 0x49D0, 
0x4AD0, 0x4BD0, 0x4CD0, 0x4DD0, 0x4ED0, 0x4FD0, 0x50D0, 0x51D0, 0x52D0, 0x53D0, 0x54D0, 0x55D0, 
0x56D0, 0x57D0, 0x58D0, 0x5AD0, 0x5BD0, 0x5CD0, 0x5DD0, 0x5FD0, 0x60D0, 0x61D0, 0x63D0, 0x64CF, 
0x65CF, 0x67CF, 0x68CF, 0x6ACF, 0x6BCE, 0x6CCE, 0x6ECE, 0x6FCE, 0x71CD, 0x72CD, 0x74CD, 0x75CD, 
0x77CC, 0x78CC, 0x7ACB, 0x7BCB, 0x7DCB, 0x7FCA, 0x80CA, 0x82CA, 0x83C9, 0x85C9, 0x86C8, 0x88C8, 
0x89C7, 0x8BC7, 0x8DC6, 0x8EC6, 0x90C5, 0x91C5, 0x93C4, 0x94C4, 0x96C3, 0x98C2, 0x99C2, 0x9BC1, 
0x9CC1, 0x9EC0, 0x9FBF, 0xA1BF, 0xA2BE, 0xA4BD, 0xA5BD, 0xA7BC, 0xA8BB, 0xA9BB, 0xABBA, 0xACB9, 
0xAEB9, 0xAFB8, 0xB0B7, 0xB2B6, 0xB3B6, 0xB4B5, 0xB6B4, 0xB7B3, 0xB8B2, 0xB9B2, 0xBBB1, 0xBCB0, 
0xBDAF, 0xBEAE, 0xBFAE, 0xC0AD, 0xC1AC, 0xC2AB, 0xC3AA, 0xC4A9, 0xC5A8, 0xC6A8, 0xC7A7, 0xC8A6, 
0xC9A5, 0xCAA4, 0xCAA3, 0xCBA2, 0xCCA1, 0xCDA0, 0xCD9F, 0xCE9F, 0xCF9E, 0xCF9D, 0xD09C, 0xD09B, 
0xD19A, 0xD199, 0xD298, 0xD297, 0xD396, 0xD395, 0xD394, 0xD393, 0xD492, 0xD491, 0xD490, 0xD48F, 
0xD48E, 0xD48D, 0xD48C, 0xD58C, 0xD48B, 0xD48A, 0xD489, 0xD488, 0xD487, 0xD486, 0xD485, 0xD384, 
0xD383, 0xD382, 0xD381, 0xD280, 0xD27F, 0xD17E, 0xD17D, 0xD07C, 0xD07B, 0xCF7A, 0xCF79, 0xCE78, 
0xCD78, 0xCD77, 0xCC76, 0xCB75, 0xCA74, 0xCA73, 0xC972, 0xC871, 0xC770, 0xC66F, 0xC56F, 0xC46E, 
0xC36D, 0xC26C, 0xC16B, 0xC06A, 0xBF69, 0xBE69, 0xBD68, 0xBC67, 0xBB66, 0xB965, 0xB865, 0xB764, 
0xB663, 0xB462, 0xB361, 0xB261, 0xB060, 0xAF5F, 0xAE5E, 0xAC5E, 0xAB5D, 0xA95C, 0xA85C, 0xA75B, 
0xA55A, 0xA45A, 0xA259, 0xA158, 0x9F58, 0x9E57, 0x9C56, 0x9B56, 0x9955, 0x9855, 0x9654, 0x9453, 
0x9353, 0x9152, 0x9052, 0x8E51, 0x8D51, 0x8B50, 0x8A50, 0x884F, 0x864F, 0x854E, 0x834E, 0x824D, 
0x804D, 0x7F4D, 0x7D4C, 0x7B4C, 0x7A4C, 0x784B, 0x774B, 0x754A, 0x744A, 0x724A, 0x714A, 0x6F49, 
0x6E49, 0x6C49, 0x6B49, 0x6A48, 0x6848, 0x6748, 0x6548, 0x6448, 0x6347, 0x6147, 0x6047, 0x5F47, 
0x5D47, 0x5C47, 0x5B47, 0x5A47, 0x5847, 0x5747, 0x5647, 0x5547, 0x5447, 0x5347, 0x5247, 0x5147, 
0x5047, 0x4F47, 0x4E47, 0x4D47, 0x4C47, 0x4B47, 0x4A47, 0x4947, 0x4948, 0x4848, 0x4748, 0x4648, 
0x4648, 0x4549, 0x4449, 0x4449, 0x4349, 0x434A, 0x424A, 0x424A, 0x414A, 0x414B, 0x404B, 0x404C, 
0x404C, 0x404C, 0x3F4D, 0x3F4D, 0x3F4D, 0x3F4E, 0x3F4E, 0x3F4F, 0x3F4F, 0x3F50, 0x3F50, 0x3F51, 
0x3F51, 0x3F52, 0x3F52, 0x3F53, 0x3F53, 0x4054, 0x4055, 0x4055, 0x4056, 0x4156, 0x4157, 0x4258, 
0x4258, 0x4359, 0x435A, 0x445A, 0x445B, 0x455C, 0x465C, 0x465D, 0x475E, 0x485E, 0x495F, 0x4960, 
0x4A61, 0x4B61, 0x4C62, 0x4D63, 0x4E64, 0x4F65, 0x5065, 0x5166, 0x5267, 0x5368, 0x5469, 0x5569, 
0x566A, 0x576B, 0x586C, 0x5A6D, 0x5B6E, 0x5C6F, 0x5D6F, 0x5F70, 0x6071, 0x6172, 0x6373, 0x6474, 
0x6575, 0x6776, 0x6877, 0x6A78, 0x6B78, 0x6C79, 0x6E7A, 0x6F7B, 0x717C, 0x727D, 0x747E, 0x757F, 
0x7780, 0x7881, 0x7A82, 0x7B83, 0x7D84, 0x7F85, 0x8086, 0x8287, 0x8388, 0x8589, 0x868A, 0x888B
};

static unsigned short epitrochoid_pos_table0[] = {
0x80B0, 0x7FB0, 0x7EB0, 0x7DB0, 0x7DB0, 0x7CB0, 0x7BB0, 0x7BB1, 0x7AB1, 0x7AB1, 0x79B2, 0x79B2, 
0x78B3, 0x78B4, 0x77B4, 0x77B5, 0x76B6, 0x76B6, 0x76B7, 0x75B8, 0x75B9, 0x75BA, 0x75BA, 0x75BB, 
0x75BC, 0x75BD, 0x75BE, 0x75BF, 0x75C0, 0x75C1, 0x75C2, 0x76C3, 0x76C4, 0x76C5, 0x77C6, 0x77C7, 
0x78C8, 0x78C9, 0x79CA, 0x7ACB, 0x7BCC, 0x7BCC, 0x7CCD, 0x7DCE, 0x7ECF, 0x7FD0, 0x80D0, 0x81D1, 
0x82D2, 0x83D2, 0x85D3, 0x86D4, 0x87D4, 0x88D4, 0x8AD5, 0x8BD5, 0x8CD5, 0x8ED6, 0x8FD6, 0x90D6, 
0x92D6, 0x93D6, 0x95D6, 0x96D6, 0x97D6, 0x99D6, 0x9AD6, 0x9CD5, 0x9DD5, 0x9ED5, 0xA0D4, 0xA1D4, 
0xA3D3, 0xA4D2, 0xA5D2, 0xA7D1, 0xA8D0, 0xA9CF, 0xAACF, 0xABCE, 0xACCD, 0xAECC, 0xAFCB, 0xB0CA, 
0xB1C9, 0xB1C8, 0xB2C6, 0xB3C5, 0xB4C4, 0xB5C3, 0xB5C2, 0xB6C0, 0xB7BF, 0xB7BE, 0xB8BC, 0xB8BB, 
0xB8BA, 0xB9B9, 0xB9B7, 0xB9B6, 0xB9B5, 0xB9B3, 0xB9B2, 0xB9B1, 0xB9AF, 0xB9AE, 0xB9AD, 0xB9AC, 
0xB8AB, 0xB8A9, 0xB8A8, 0xB7A7, 0xB7A6, 0xB6A5, 0xB6A4, 0xB5A3, 0xB5A2, 0xB4A1, 0xB3A0, 0xB3A0, 
0xB29F, 0xB19E, 0xB19E, 0xB09D, 0xAF9C, 0xAE9C, 0xAD9B, 0xAD9B, 0xAC9B, 0xAB9A, 0xAA9A, 0xA99A, 
0xA89A, 0xA89A, 0xA79A, 0xA699, 0xA59A, 0xA49A, 0xA49A, 0xA39A, 0xA29A, 0xA29A, 0xA19B, 0xA09B, 
0xA09B, 0x9F9C, 0x9F9C, 0x9E9D, 0x9E9D, 0x9D9E, 0x9D9F, 0x9D9F, 0x9CA0, 0x9CA0, 0x9CA1, 0x9CA2, 
0x9CA2, 0x9CA3, 0x9CA4, 0x9CA5, 0x9CA5, 0x9CA6, 0x9CA7, 0x9CA7, 0x9DA8, 0x9DA9, 0x9EAA, 0x9EAA, 
0x9FAB, 0x9FAC, 0xA0AC, 0xA0AD, 0xA1AD, 0xA2AE, 0xA2AE, 0xA3AF, 0xA4AF, 0xA5B0, 0xA6B0, 0xA7B0, 
0xA8B1, 0xA9B1, 0xAAB1, 0xABB1, 0xACB1, 0xADB1, 0xAEB1, 0xAFB1, 0xB0B1, 0xB2B1, 0xB3B1, 0xB4B1, 
0xB5B0, 0xB6B0, 0xB7AF, 0xB9AF, 0xBAAF, 0xBBAE, 0xBCAD, 0xBDAD, 0xBEAC, 0xBFAB, 0xC0AA, 0xC1A9, 
0xC2A8, 0xC3A8, 0xC4A7, 0xC5A5, 0xC6A4, 0xC7A3, 0xC8A2, 0xC8A1, 0xC9A0, 0xCA9E, 0xCA9D, 0xCB9C, 
0xCB9A, 0xCC99, 0xCC98, 0xCD96, 0xCD95, 0xCD93, 0xCD92, 0xCD90, 0xCD8F, 0xCE8E, 0xCD8C, 0xCD8B, 
0xCD89, 0xCD88, 0xCD86, 0xCD85, 0xCC83, 0xCC82, 0xCB81, 0xCB7F, 0xCA7E, 0xCA7D, 0xC97B, 0xC87A, 
0xC879, 0xC778, 0xC677, 0xC576, 0xC474, 0xC373, 0xC273, 0xC172, 0xC071, 0xBF70, 0xBE6F, 0xBD6E, 
0xBC6E, 0xBB6D, 0xBA6C, 0xB96C, 0xB76C, 0xB66B, 0xB56B, 0xB46A, 0xB36A, 0xB26A, 0xB06A, 0xAF6A, 
0xAE6A, 0xAD6A, 0xAC6A, 0xAB6A, 0xAA6A, 0xA96A, 0xA86A, 0xA76B, 0xA66B, 0xA56B, 0xA46C, 0xA36C, 
0xA26D, 0xA26D, 0xA16E, 0xA06E, 0xA06F, 0x9F6F, 0x9F70, 0x9E71, 0x9E71, 0x9D72, 0x9D73, 0x9C74, 
0x9C74, 0x9C75, 0x9C76, 0x9C76, 0x9C77, 0x9C78, 0x9C79, 0x9C79, 0x9C7A, 0x9C7B, 0x9C7B, 0x9D7C, 
0x9D7D, 0x9D7D, 0x9E7E, 0x9E7E, 0x9F7F, 0x9F7F, 0xA080, 0xA080, 0xA180, 0xA281, 0xA281, 0xA381, 
0xA481, 0xA481, 0xA581, 0xA682, 0xA781, 0xA881, 0xA881, 0xA981, 0xAA81, 0xAB81, 0xAC80, 0xAD80, 
0xAD80, 0xAE7F, 0xAF7F, 0xB07E, 0xB17D, 0xB17D, 0xB27C, 0xB37B, 0xB37B, 0xB47A, 0xB579, 0xB578, 
0xB677, 0xB676, 0xB775, 0xB774, 0xB873, 0xB872, 0xB870, 0xB96F, 0xB96E, 0xB96D, 0xB96C, 0xB96A, 
0xB969, 0xB968, 0xB966, 0xB965, 0xB964, 0xB962, 0xB861, 0xB860, 0xB85F, 0xB75D, 0xB75C, 0xB65B, 
0xB559, 0xB558, 0xB457, 0xB356, 0xB255, 0xB153, 0xB152, 0xB051, 0xAF50, 0xAE4F, 0xAC4E, 0xAB4D, 
0xAA4C, 0xA94C, 0xA84B, 0xA74A, 0xA549, 0xA449, 0xA348, 0xA147, 0xA047, 0x9E46, 0x9D46, 0x9C46, 
0x9A45, 0x9945, 0x9745, 0x9645, 0x9545, 0x9345, 0x9245, 0x9045, 0x8F45, 0x8E45, 0x8C46, 0x8B46, 
0x8A46, 0x8847, 0x8747, 0x8647, 0x8548, 0x8349, 0x8249, 0x814A, 0x804B, 0x7F4B, 0x7E4C, 0x7D4D, 
0x7C4E, 0x7B4F, 0x7B4F, 0x7A50, 0x7951, 0x7852, 0x7853, 0x7754, 0x7755, 0x7656, 0x7657, 0x7658, 
0x7559, 0x755A, 0x755B, 0x755C, 0x755D, 0x755E, 0x755F, 0x7560, 0x7561, 0x7561, 0x7562, 0x7563, 
0x7664, 0x7665, 0x7665, 0x7766, 0x7767, 0x7867, 0x7868, 0x7969, 0x7969, 0x7A6A, 0x7A6A, 0x7B6A, 
0x7B6B, 0x7C6B, 0x7D6B, 0x7D6B, 0x7E6B, 0x7F6B, 0x7F6C, 0x806B, 0x816B, 0x826B, 0x826B, 0x836B, 
0x846B, 0x846A, 0x856A, 0x856A, 0x8669, 0x8669, 0x8768, 0x8767, 0x8867, 0x8866, 0x8965, 0x8965, 
0x8964, 0x8A63, 0x8A62, 0x8A61, 0x8A61, 0x8A60, 0x8A5F, 0x8A5E, 0x8A5D, 0x8A5C, 0x8A5B, 0x8A5A, 
0x8A59, 0x8958, 0x8957, 0x8956, 0x8855, 0x8854, 0x8753, 0x8752, 0x8651, 0x8550, 0x844F, 0x844F, 
0x834E, 0x824D, 0x814C, 0x804B, 0x7F4B, 0x7E4A, 0x7D49, 0x7C49, 0x7A48, 0x7947, 0x7847, 0x7747, 
0x7546, 0x7446, 0x7346, 0x7145, 0x7045, 0x6F45, 0x6D45, 0x6C45, 0x6A45, 0x6945, 0x6845, 0x6645, 
0x6545, 0x6346, 0x6246, 0x6146, 0x5F47, 0x5E47, 0x5C48, 0x5B49, 0x5A49, 0x594A, 0x574B, 0x564C, 
0x554C, 0x544D, 0x534E, 0x514F, 0x5050, 0x4F51, 0x4E52, 0x4E53, 0x4D55, 0x4C56, 0x4B57, 0x4A58, 
0x4A59, 0x495B, 0x485C, 0x485D, 0x475F, 0x4760, 0x4761, 0x4662, 0x4664, 0x4665, 0x4666, 0x4668, 
0x4669, 0x466A, 0x466C, 0x466D, 0x466E, 0x466F, 0x4770, 0x4772, 0x4773, 0x4874, 0x4875, 0x4976, 
0x4977, 0x4A78, 0x4A79, 0x4B7A, 0x4C7B, 0x4C7B, 0x4D7C, 0x4E7D, 0x4E7D, 0x4F7E, 0x507F, 0x517F, 
0x5280, 0x5280, 0x5380, 0x5481, 0x5581, 0x5681, 0x5781, 0x5781, 0x5881, 0x5982, 0x5A81, 0x5B81, 
0x5B81, 0x5C81, 0x5D81, 0x5D81, 0x5E80, 0x5F80, 0x5F80, 0x607F, 0x607F, 0x617E, 0x617E, 0x627D, 
0x627D, 0x627C, 0x637B, 0x637B, 0x637A, 0x6379, 0x6379, 0x6378, 0x6377, 0x6376, 0x6376, 0x6375, 
0x6374, 0x6374, 0x6273, 0x6272, 0x6171, 0x6171, 0x6070, 0x606F, 0x5F6F, 0x5F6E, 0x5E6E, 0x5D6D, 
0x5D6D, 0x5C6C, 0x5B6C, 0x5A6B, 0x596B, 0x586B, 0x576A, 0x566A, 0x556A, 0x546A, 0x536A, 0x526A, 
0x516A, 0x506A, 0x4F6A, 0x4D6A, 0x4C6A, 0x4B6A, 0x4A6B, 0x496B, 0x486C, 0x466C, 0x456C, 0x446D, 
0x436E, 0x426E, 0x416F, 0x4070, 0x3F71, 0x3E72, 0x3D73, 0x3C73, 0x3B74, 0x3A76, 0x3977, 0x3878, 
0x3779, 0x377A, 0x367B, 0x357D, 0x357E, 0x347F, 0x3481, 0x3382, 0x3383, 0x3285, 0x3286, 0x3288, 
0x3289, 0x328B, 0x328C, 0x328E, 0x328F, 0x3290, 0x3292, 0x3293, 0x3295, 0x3296, 0x3398, 0x3399, 
0x349A, 0x349C, 0x359D, 0x359E, 0x36A0, 0x37A1, 0x37A2, 0x38A3, 0x39A4, 0x3AA5, 0x3BA7, 0x3CA8, 
0x3DA8, 0x3EA9, 0x3FAA, 0x40AB, 0x41AC, 0x42AD, 0x43AD, 0x44AE, 0x45AF, 0x46AF, 0x48AF, 0x49B0, 
0x4AB0, 0x4BB1, 0x4CB1, 0x4DB1, 0x4FB1, 0x50B1, 0x51B1, 0x52B1, 0x53B1, 0x54B1, 0x55B1, 0x56B1, 
0x57B1, 0x58B0, 0x59B0, 0x5AB0, 0x5BAF, 0x5CAF, 0x5DAE, 0x5DAE, 0x5EAD, 0x5FAD, 0x5FAC, 0x60AC, 
0x60AB, 0x61AA, 0x61AA, 0x62A9, 0x62A8, 0x63A7, 0x63A7, 0x63A6, 0x63A5, 0x63A5, 0x63A4, 0x63A3, 
0x63A2, 0x63A2, 0x63A1, 0x63A0, 0x63A0, 0x629F, 0x629F, 0x629E, 0x619D, 0x619D, 0x609C, 0x609C, 
0x5F9B, 0x5F9B, 0x5E9B, 0x5D9A, 0x5D9A, 0x5C9A, 0x5B9A, 0x5B9A, 0x5A9A, 0x5999, 0x589A, 0x579A, 
0x579A, 0x569A, 0x559A, 0x549A, 0x539B, 0x529B, 0x529B, 0x519C, 0x509C, 0x4F9D, 0x4E9E, 0x4E9E, 
0x4D9F, 0x4CA0, 0x4CA0, 0x4BA1, 0x4AA2, 0x4AA3, 0x49A4, 0x49A5, 0x48A6, 0x48A7, 0x47A8, 0x47A9, 
0x47AB, 0x46AC, 0x46AD, 0x46AE, 0x46AF, 0x46B1, 0x46B2, 0x46B3, 0x46B5, 0x46B6, 0x46B7, 0x46B9, 
0x47BA, 0x47BB, 0x47BC, 0x48BE, 0x48BF, 0x49C0, 0x4AC2, 0x4AC3, 0x4BC4, 0x4CC5, 0x4DC6, 0x4EC8, 
0x4EC9, 0x4FCA, 0x50CB, 0x51CC, 0x53CD, 0x54CE, 0x55CF, 0x56CF, 0x57D0, 0x59D1, 0x5AD2, 0x5BD2, 
0x5CD3, 0x5ED4, 0x5FD4, 0x61D5, 0x62D5, 0x63D5, 0x65D6, 0x66D6, 0x68D6, 0x69D6, 0x6AD6, 0x6CD6, 
0x6DD6, 0x6FD6, 0x70D6, 0x71D6, 0x73D5, 0x74D5, 0x75D5, 0x77D4, 0x78D4, 0x79D4, 0x7AD3, 0x7CD2, 
0x7DD2, 0x7ED1, 0x7FD0, 0x80D0, 0x81CF, 0x82CE, 0x83CD, 0x84CC, 0x84CC, 0x85CB, 0x86CA, 0x87C9, 
0x87C8, 0x88C7, 0x88C6, 0x89C5, 0x89C4, 0x89C3, 0x8AC2, 0x8AC1, 0x8AC0, 0x8ABF, 0x8ABE, 0x8ABD, 
0x8ABC, 0x8ABB, 0x8ABA, 0x8ABA, 0x8AB9, 0x8AB8, 0x89B7, 0x89B6, 0x89B6, 0x88B5, 0x88B4, 0x87B4, 
0x87B3, 0x86B2, 0x86B2, 0x85B1, 0x85B1, 0x84B1, 0x84B0, 0x83B0, 0x82B0, 0x82B0, 0x81B0, 0x80B0
};

static struct HypotrochoidsEtAl hypotrochoids[] = {
  {
    sizeof(epitrochoid_pos_table0) / sizeof(unsigned short),
    epitrochoid_pos_table0
  },
  {
    sizeof(lissajou_pos_table0) / sizeof(unsigned short),
    lissajou_pos_table0,
  },
  {
    sizeof(hypotrochoid_pos_table0) / sizeof(unsigned short),
    &hypotrochoid_pos_table0[0]
  },
};
static int hypotrochoid_current = 0;
/* pointer to a bitplane */
static unsigned char *bitplaneptr;
static unsigned short hypotrochoid_phase[NUMBER_of_SOBS];
/* 
 * This will contain an array of arrays which can be used to display a
 * sprite. The memory is not initialised and must be filled. We
 * allocate memory for 16 sprites to double buffer the array in order
 * to eliminate tearing.
 *
 * It is assumed that the sprite has a height of SPRITE_HEIGHT pixel.
 */
static unsigned short *sprite_array[16];
/*! \brief Structure for sprite multiplexer
 *
 * This structure is used for the sprite multiplexer. It must be
 * available two times as we have to use double buffering in order to
 * reduce tearing, etc. As the sprite multiplexer changes the sprite
 * data while multiplexing sprites this is necessary.
 */
static struct Multiplexer multiplex[2];
static UWORD *coplist;
static UWORD coplist_data[] = {
  0x0180, 0, /* background black */
  0x0182, 0x0eef, /* Colour 1: not quite white */
  /* Set sprite pointer of sprite 0, 1, ...; will be replaced later. */
  0x0120, 0x0000, 0x0122, 0x0000,
  0x0124, 0x0000, 0x0126, 0x0000,
  0x0128, 0x0000, 0x012a, 0x0000,
  0x012c, 0x0000, 0x012e, 0x0000,
  0x0130, 0x0000, 0x0132, 0x0000,
  0x0134, 0x0000, 0x0136, 0x0000,
  0x0138, 0x0000, 0x013a, 0x0000,
  0x013c, 0x0000, 0x013e, 0x0000,
  /* Bitplane pointers */
  0x00e0, 0, 0x00e2, 0,
  0x00e4, 0, 0x00e6, 0,
  /* Sprites, colour 16, etc. $180+2*16=$1a0 */
  0x01a0,0x0fff,0x01a2,0x0b41,0x01a4,0x0ad4,0x01a6,0x0059,
  0x01a8,0x0fff,0x01aa,0x0b41,0x01ac,0x0ad4,0x01ae,0x0059,
  0x01b0,0x0fff,0x01b2,0x0b41,0x01b4,0x0ad4,0x01b6,0x0059,
  0x01b8,0x0fff,0x01ba,0x0b41,0x01bc,0x0ad4,0x01be,0x0059,
  /* Other registers */
  0x0100, 0x1200, // BPLCON0, one bitplane.
  0x0104, 0x0024, // BPLCON2, sprites have priority.
  0x102, 0, // BPLCON1
  0x0108, 0, // BPL1MOD
  0x010a, 0, // BPL2MOD
  0x008a, 0, // COPJMP2
  0xFFFF, 0xFFFE
};
static UWORD *coplist_spriteptr; //!< Pointer to where in the copperlist the sprite pointers are set.

/*! \brief Initialise the multiplex structure
 */
static void init_multiplex(void) {
  int i;

  for(i = 0; i < 8; ++i) {
    multiplex[0].sprite_data[i] = &(sprite_array[i][0]);
    multiplex[1].sprite_data[i] = &(sprite_array[i+8][0]);
  }
  multiplex[0].numsprites = 8;
  multiplex[1].numsprites = 8;
}

/*! \brief Set the eight sprite pointers in a copper list
 *
 * The eight sprite pointer ($120 to $13e) are set via the copper in
 * each vertical blank. This function will change the copperlist to
 * the new sprite memory-pointers.
 *
 * \param copptr Pointer in the copperlist where register $120 is set
 * \param sprmem Pointer to an array of 8 pointers with sprite memory.
 */
void copper_set_sprite_pointers(UWORD *copptr, unsigned short **sprmem) {
  int spr;

  for(spr = 0; spr < 8; ++spr) {
    copptr[4 * spr + 1] = (ULONG)(&(sprmem[spr][0])) >> 16;
    copptr[4 * spr + 3] = (ULONG)(&(sprmem[spr][0])) & 0xFFFF;
  }
}

static void init_copper(void *bitpl0) {
  UWORD *ptr;

  coplist = circalloc(sizeof(coplist_data));
  memcpy(coplist, coplist_data, sizeof(coplist_data));
  for(ptr = coplist; *ptr != 0xFFFF; ptr += 2) {
    if(*ptr == 0x0120) {
      coplist_spriteptr = ptr; // Store this for easy use later on.
      copper_set_sprite_pointers(ptr, sprite_array);
    } else if(*ptr == 0x00e0) /*bitplane0 pointer*/ {
      ptr[1] = (ULONG)bitpl0 >> 16;
      ptr[3] = (ULONG)bitpl0 & 0xFFFF;
    }
  }
}

/*! Sort hypotrochoids phase-array
 *
 * This function will take an array of phases and sort them according
 * to their value in the hypotrochoid_pos_table.
 *
 * The sorting algorithm used is the Gnome Sort, see
 * https://en.wikipedia.org/wiki/Gnome_sort, in its unoptimized
 * variant. This is much more stable and even faster than Bubble
 * Sort. If a higher speed is necessary the optimised variant may be
 * an option.
 *
 * @param phases poiner the the phases of the SOBs
 * @param num number of elements in the array
 */
void sort_hypotrochoids(unsigned short *phases, unsigned short num) {
  register unsigned short pos;
  register unsigned short temp;
  unsigned short *postable;

  pos = 0;
  postable = hypotrochoids[hypotrochoid_current].pos_table;
  while(pos < num) {
    /* Either first element or already in right order. */
    if((pos == 0) || (postable[phases[pos]] >= postable[phases[pos - 1]])) {
      ++pos;
    } else {
      /* SWAP */
      temp = phases[pos - 1];
      phases[pos - 1] = phases[pos];
      phases[pos] = temp;
      /* decrement pos */
      --pos;
    }
  }
}

/*
 * This function is called by the assembler interrupt subroutine.
 */
static void do_interrupt_warp(void) {
  short i;
  unsigned short xpos;
  unsigned short spos;
  short sum = 0;

  for(i = 0; i < sizeof(hypotrochoid_phase)/sizeof(unsigned short int); ++i) {
    if(++hypotrochoid_phase[i] >= hypotrochoids[hypotrochoid_current].table_length) {
      hypotrochoid_phase[i] = 0;
    }
  }
  sort_hypotrochoids(hypotrochoid_phase, sizeof(hypotrochoid_phase)/sizeof(unsigned short int));
  multiplex_sprites(
		    &(hypotrochoid_phase[0]),
		    NUMBER_of_SOBS, SPRITE_HEIGHT,
		    hypotrochoids[hypotrochoid_current].pos_table,
		    &multiplex[framecounter & 1]
		    );
  if((framecounter & 1) == 0) {
    copper_set_sprite_pointers(coplist_spriteptr, sprite_array);
  } else {
    copper_set_sprite_pointers(coplist_spriteptr, sprite_array + 8);
  }
}

/*! \brief Prepare the sprite data by filling the sprite information
 */
static void copy_sprite_data(void) {
  UWORD sprdat[] = {
    0x1e00,0x0000,
    0x3f00,0x0000,
    0x6780,0x1800,
    0xc3c0,0x3c40,
    0xc3c0,0x3c40,
    0xe7c0,0x1840,
    0xffc0,0x0040,
    0x7f80,0x0080,
    0x3f00,0x0100,
    0x1e00,0x0600
  };
  int i;
  int spr;
  int reuse;
  unsigned short coor;

  for(reuse = 0; reuse < MAX_NUM_SPRITE_REUSE; ++ reuse) {
    for(spr = 0; spr < sizeof(sprite_array)/sizeof(unsigned short *); ++spr) {
      coor = 0x3000 | (0x30 + spr * 18);
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 0] = coor;
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 1] = (coor & 0xFF00) + (SPRITE_HEIGHT << 8);
      for(i = 0; i < 2*SPRITE_HEIGHT; ++i) {
	sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 2 + i] = sprdat[i];
      }
      /* End Of Sprite */
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 2 + 2*SPRITE_HEIGHT + 0] = 0;
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 2 + 2*SPRITE_HEIGHT + 1] = 0;
    }
  }
}


void hypotrochoids_part(void) {
  int i;

  bitplaneptr = circalloc(320*256/8);
  clear_bitplane(bitplaneptr, 320/8/2, 256);
  for(i = 0; i < sizeof(sprite_array)/sizeof(unsigned short *); ++i) {
    sprite_array[i] = circalloc((SPRITE_HEIGHT+2)*2*2 * MAX_NUM_SPRITE_REUSE);
#ifndef NDEBUG
    memset(sprite_array[i], -1, (SPRITE_HEIGHT+2)*2*2 * MAX_NUM_SPRITE_REUSE);
#endif
  }
  init_multiplex();
  /* Initialise SOBs. */
  for(i = 0; i < NUMBER_of_SOBS; ++i) {
    hypotrochoid_phase[i] = i * 23;
  }
  // And pre-sort in order to reduce lag on first frame.
  sort_hypotrochoids(hypotrochoid_phase, sizeof(hypotrochoid_phase)/sizeof(unsigned short int));
  init_copper(bitplaneptr);
  copy_sprite_data();
  custom.cop1lc = (ULONG)coplist;
  custom.copjmp1 = 0;
  custom.dmacon = DMAF_SETCLR /*set*/
    | DMAF_MASTER /*DMAEN*/
    | DMAF_RASTER /*BPLEN*/
    | DMAF_COPPER /*COPEN*/
    | DMAF_SPRITE /*SPREN, apparently bitplane dma has to be enabled, too */;
  autovector[0x308/4] = (ULONG)&do_interrupt_warp;
  for(i = 0; i < sizeof(hypotrochoid_text)/sizeof(const char *); ++i) {
    const char *txt = hypotrochoid_text[i];
    text_monochrome(txt,
		    get_font_address(),
		    bitplaneptr + 320/8*60 + i*10*320/8 + (40-strlen(txt))/2, 320/8
		    );
  }
  wait_songposition(4, 0);
  hypotrochoid_current = 1;
  wait_songposition(5, 0);
  hypotrochoid_current = 2;
  wait_songposition(6, 0);
  autovector[0x308/4] = 0;
  // Disable sprite DMA and remove the nasty stripes.
  custom.dmacon = DMAF_SPRITE;
  for(i = 0; i < 8; ++i) {
    custom.spr[i].datab = 0;
    custom.spr[i].dataa = 0;
    custom.spr[i].ctl = 0;
  }
}
