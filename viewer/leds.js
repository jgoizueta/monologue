const LEDS_PROPERTIES = {
    'value': ['value', parseInt],
    'min-value': ['minValue', parseInt],
    'max-value': ['maxValue', parseInt],
    'vertical': ['vertical', v => true],
  };

  class Leds extends HTMLElement {
    static get observedAttributes() {
      return Object.keys(LEDS_PROPERTIES);
    }

    static get defaultAttributeValues() {
        return {
            value: undefined,
            minValue: 1,
            maxValue: 5,
            vertical: false,
        };
    }

    constructor() {
        console.log("CONS");
      super();
      this.enabled = false;
      const shadow = this.attachShadow({mode: 'open'});
      const canvas = document.createElement('canvas');
      shadow.appendChild(canvas);
      this.canvas = canvas;
      this.params = Object.assign({}, Leds.defaultAttributeValues);
    }

    connectedCallback() {
        console.log('connected', this.params);
      this.enabled = true;
      render(this);
    }

    attributeChangedCallback(name, oldValue, newValue) {
        console.log("SET",name,oldValue,newValue);
      const [prop, conv] = LEDS_PROPERTIES[name];
      this.params[prop] = conv(newValue);
      render(this);
    }
  }

  customElements.define('synth-leds', Leds);

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

    const context = canvas.getContext("2d");

    const style = window.getComputedStyle(elem);

    context.fillStyle = style.backgroundColor;
    context.fillRect(0, 0, total_width, total_height);

    const colorOff = style.color;
    const colorOn = style.floodColor;

    const margin = parseFloat(style.padding);
    const size = params.vertical ? total_width-2*margin : total_height-2*margin;

    for (let i=params.minValue; i<=params.maxValue; i++) {
        const x = params.vertical ? margin : (i - params.minValue)*(size + margin) + margin;
        const y = params.vertical ? (i - params.minValue)*(size + margin) + margin : margin;
        const color = (i == params.value) ? colorOn : colorOff;
        context.fillStyle = color;
        context.strokeStyle = 'green';
        context.beginPath();
        context.arc(x + size/2, total_height - y - size/2, size/2, 0, 2 * Math.PI);
        context.fill();
    }
  }
