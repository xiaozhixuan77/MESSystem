@ComponentV2
export struct StatusTag {
  @Param status: string = '';
  private getColor(): ResourceColor {
    const map: Record<string, ResourceColor> = {
      '待派工': '#999','已派工': '#1890ff','生产中': '#52c41a','暂停中': '#faad14',
      '生产完成': '#722ed1','已报工': '#13c2c2','完工': '#52c41a','报废': '#f5222d','异常': '#f5222d'
    };
    return map[this.status] || '#999';
  }
  build() {
    Text(this.status).fontSize(12).fontColor(this.getColor())
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .backgroundColor(`${this.getColor()}20`).borderRadius(4);
  }
}
