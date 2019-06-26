const PROPERTIES = {
  'value': ['value', parseFloat],
  'min-value': ['minValue', parseFloat],
  'max-value': ['maxValue', parseFloat],
  'min-pos': ['minPos', parseFloat],
  'max-pos': ['maxPos', parseFloat],
  'margin': ['margin', parseFloat],
  'ref-pos': ['refPos', parseFloat],
};

class Knob extends HTMLElement {
  static get observedAttributes() {
    return Object.keys(PROPERTIES);
  }

  static get defaultAttributeValues() {
      return {
          value: undefined,
          minValue: 0,
          maxValue: 1023,
          minPos: -150,
          maxPos: 150,
          margin: 4,
          refPos: 90, // positions relative to top
      };
  }

  constructor() {
    super();
    this.enabled = false;
    const shadow = this.attachShadow({mode: 'open'});
    const canvas = document.createElement('canvas');
    shadow.appendChild(canvas);
    this.canvas = canvas;
    this.params = Object.assign({}, Knob.defaultAttributeValues);
  }

  connectedCallback() {
    this.enabled = true;
    render(this);
  }

  attributeChangedCallback(name, oldValue, newValue) {
    const [prop, conv] = PROPERTIES[name];
    this.params[prop] = conv(newValue);
    render(this);
  }
}

customElements.define('synth-knob', Knob);

function render(elem) {
  if (!elem.enabled) {
      return;
  }
  // const canvas = elem.getElementsByTagName('canvas')[0];
  const canvas = elem.canvas;
  canvas.width  = parseFloat(window.getComputedStyle(elem).width);
  canvas.height = parseFloat(window.getComputedStyle(elem).height);

  const params = elem.params;

  const total_width = canvas.width;
  const total_height = canvas.height;
  const width = total_width - 2*params.margin;
  const height = total_height - 2*params.margin;

  const context = canvas.getContext("2d");

  const r = Math.min(width, height) / 2;
  const cx = total_width / 2;
  const cy = total_height / 2;

  const style = window.getComputedStyle(elem);

  context.fillStyle = style.backgroundColor;
  context.fillRect(0, 0, total_width, total_height);

  const color = style.color;
  const markColor = style.borderColor;

  context.lineWidth = 2;
  context.strokeStyle = color;
  context.beginPath();
  context.arc(cx, cy, r, 0, 2 * Math.PI);
  if (style.floodColor !== color) {
    context.fillStyle = style.floodColor;
    context.fill();
  }
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

  marker(0, markColor, r+3, r+5);
  marker(1, markColor, r+3, r+5);

  const fraction = (params.value - params.minValue) / (params.maxValue - params.minValue);
  marker(fraction, color);
}