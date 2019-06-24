(function( $ ) {
  console.log('loading knob....');
  $.fn.knob = function(fparams) {
    return this.each(function() {
      const canvas = $(this);
      const params = $.extend({}, $.fn.knob.defaults, fparams, canvas.data());

      // @height(), @width() corresponds to the CSS height & width of the canvas element
      // this.height, this.width are the attributes of the HTML element (<canvas width="..." height="...")
      // The latter define the coordinate system of the canvas
      // To avoid having to set the HTML attributes (and use only the CSS properties) we will copy:
      this.width = canvas.width();
      this.height = canvas.height();

      const total_width = canvas.width();
      const total_height = canvas.height();
      const width = total_width - 2*params.margin;
      const height = total_height - 2*params.margin;

      const context = this.getContext("2d");

      const r = Math.min(width, height) / 2;
      const cx = total_width / 2;
      const cy = total_height / 2;

      // Background
      context.fillStyle = params.colorBackground;
      context.fillRect(0, 0, total_width, total_height);

      context.lineWidth = 2;
      context.strokeStyle = params.color;
      context.beginPath();
      context.arc(cx, cy, r, 0, 2 * Math.PI);
      context.stroke();

      const posAngle = (pos) => {
        return (params.refPos - pos)*Math.PI/180;
      }

      const fractionAngle = (fraction) => {
        const pos = params.minPos + fraction*(params.maxPos - params.minPos);
        return posAngle(pos);
      }

      const radPnt = (angle, r) => {
        return [cx + r*Math.cos(angle), total_height - cy - r*Math.sin(angle)];
      }

      const marker = (fraction, color, r1 = 0, r2 = r) => {
        const angle = fractionAngle(fraction);
        const [x1, y1] = radPnt(angle, r1);
        const [x2, y2] = radPnt(angle, r2);
        context.strokeStyle = color;
        context.beginPath();
        context.moveTo(x1, y1);
        context.lineTo(x2, y2);
        context.stroke();
      }

      marker(0, params.colorDim, r+2, r+4);
      marker(1, params.colorDim, r+2, r+4);

      const fraction = (params.value - params.minValue) / (params.maxValue - params.minValue);
      marker(fraction, params.color);

      console.log(params);
      return this;
    });
  };

  $.fn.knob.defaults = {
    minValue: 0,
    maxValue: 100,
    minPos: -180,
    maxPos: 180,
    margin: 4,
    refPos: 90, // positions relatie to top
    color: '#202020',
    colorBackground: "#FFFFFF",
    colorDim: '#A0A0A0'
  };
})( jQuery );
