/**
 * MES 设计系统 — 排版令牌
 * 基于现有项目的字号使用模式，规范化层级
 * 系统默认字体 (HarmonyOS sans-serif)，预留自定义字体接口
 *
 * 引用方式：import { Typography } from '@ohos/utils'
 */

interface TextStyle {
  fontSize: number;
  fontWeight: number;
  fontColor: string;
}

export class Typography {
  // ============================================================
  // 字号层级 (vp)
  // ============================================================

  // Micro (badges, meta)
  static readonly text10 = 10;
  static readonly text11 = 11;

  // Small (labels, secondary text, tabs)
  static readonly text12 = 12;
  static readonly text13 = 13;

  // Body (primary content)
  static readonly text14 = 14;
  static readonly text15 = 15;
  static readonly text16 = 16;

  // Heading
  static readonly text18 = 18;
  static readonly text20 = 20;
  static readonly text22 = 22;

  // Display (KPIs, hero values)
  static readonly text24 = 24;
  static readonly text26 = 26;
  static readonly text28 = 28;
  static readonly text36 = 36;

  // ============================================================
  // 语义字号
  // ============================================================
  static readonly caption = 10;
  static readonly label = 12;
  static readonly body = 14;
  static readonly bodyLarge = 16;
  static readonly subtitle = 15;
  static readonly title = 18;
  static readonly heading = 20;
  static readonly hero = 24;

  // ============================================================
  // 字重
  // ============================================================
  static readonly weightRegular = 400;
  static readonly weightMedium = 500;
  static readonly weightSemibold = 600;
  static readonly weightBold = 700;

  // ============================================================
  // 行高 (ratio)
  // ============================================================
  static readonly lineHeightTight = 1.2;
  static readonly lineHeightNormal = 1.5;
  static readonly lineHeightRelaxed = 1.75;

  // ============================================================
  // 预设样式组合
  // ============================================================
  static readonly pageTitle: TextStyle = { fontSize: 18, fontWeight: 700, fontColor: '#1A1A2E' };
  static readonly sectionTitle: TextStyle = { fontSize: 14, fontWeight: 600, fontColor: '#1A1A2E' };
  static readonly cardTitle: TextStyle = { fontSize: 15, fontWeight: 600, fontColor: '#1A1A2E' };
  static readonly bodyText: TextStyle = { fontSize: 14, fontWeight: 400, fontColor: '#5A5A6E' };
  static readonly captionText: TextStyle = { fontSize: 12, fontWeight: 400, fontColor: '#9A9AA8' };
  static readonly kpiValue: TextStyle = { fontSize: 24, fontWeight: 700, fontColor: '#1565C0' };
  static readonly kpiLabel: TextStyle = { fontSize: 12, fontWeight: 400, fontColor: '#9A9AA8' };
  static readonly fieldLabel: TextStyle = { fontSize: 11, fontWeight: 400, fontColor: '#9A9AA8' };
  static readonly fieldValue: TextStyle = { fontSize: 14, fontWeight: 600, fontColor: '#1A1A2E' };
}
