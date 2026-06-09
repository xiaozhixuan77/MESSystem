import { DailyRateModel } from '../Model/DashboardModel';

function drawChart(
  ctx: CanvasRenderingContext2D,
  width: number,
  height: number,
  rates: DailyRateModel[]
): void {
  if (!rates || rates.length === 0) {
    ctx.font = '24px sans-serif';
    ctx.fillStyle = '#9A9AA8';
    ctx.textAlign = 'center';
    ctx.fillText('暂无月度数据', width / 2, height / 2);
    return;
  }

  ctx.clearRect(0, 0, width, height);

  const padLeft: number = 40;
  const padRight: number = 10;
  const padTop: number = 10;
  const padBottom: number = 30;
  const chartW: number = width - padLeft - padRight;
  const chartH: number = height - padTop - padBottom;
  const barCount: number = rates.length;
  const gapX: number = chartW / barCount;
  const barWidth: number = Math.max(4, Math.min(14, gapX * 0.5));

  // Y-axis grid + labels — 0% ~ 100%
  ctx.strokeStyle = '#F5F7FA';
  ctx.lineWidth = 1;
  for (let i: number = 0; i <= 5; i++) {
    const y: number = padTop + chartH - (i / 5) * chartH;
    if (i > 0) {
      ctx.beginPath();
      ctx.moveTo(padLeft, y);
      ctx.lineTo(width - padRight, y);
      ctx.stroke();
    }

    ctx.font = '48px sans-serif';
    ctx.fillStyle = '#9A9AA8';
    ctx.textAlign = 'right';
    ctx.fillText(`${i * 20}%`, padLeft - 6, y + 3);
  }

  // X-axis labels
  ctx.textAlign = 'center';
  ctx.fillStyle = '#9A9AA8';
  const labelInterval: number = barCount <= 10 ? 1 : (barCount <= 20 ? 3 : 5);
  for (let i: number = 0; i < barCount; i++) {
    const x: number = padLeft + i * gapX + gapX / 2;
    if (i % labelInterval === 0 || i === barCount - 1) {
      ctx.font = '48px sans-serif';
      ctx.fillText(`${rates[i].day}日`, x, height - padBottom + 16);
    }
  }

  // Bars — prototype uses #42A5F5 blue
  for (let i: number = 0; i < barCount; i++) {
    const x: number = padLeft + i * gapX;
    const rate: number = Math.min(rates[i].rate, 1.0);
    const barH: number = rate * chartH;
    const y: number = padTop + chartH - barH;

    ctx.fillStyle = '#42A5F5';
    ctx.fillRect(x + (gapX - barWidth) / 2, y, barWidth, barH);
  }
}

@ComponentV2
export struct DashboardChart {
  @Param rates: DailyRateModel[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @Local redrawKey: number = 0;

  @Monitor('rates')
  onRatesChanged(): void {
    this.redrawKey++;
  }

  build() {
    Column() {
      if (this.rates.length === 0) {
        Column() {
          Text('暂无月度数据').fontSize(13).fontColor('#9A9AA8');
        }
        .width('100%').height(160)
        .justifyContent(FlexAlign.Center);
      } else {
        Canvas(this.ctx)
          .width('100%')
          .height(160)
          .key(`${this.redrawKey}`)
          .onReady(() => {
            const w: number = this.ctx.width;
            const h: number = this.ctx.height;
            if (w > 0 && h > 0) {
              drawChart(this.ctx, w, h, this.rates);
            }
          });
      }
    }
    .width('100%');
  }
}
