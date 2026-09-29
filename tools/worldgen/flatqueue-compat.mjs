// Compatibility implementation for Azgaar's legacy FlatQueue browser global.
// Azgaar normally loads FlatQueue from public/libs/flatqueue.js via a classic script.
// The source handoff intentionally omits public/, so the headless harness supplies
// the same min-priority-queue API without modifying vendored Azgaar source.
export default class FlatQueue {
  constructor() {
    this.ids = [];
    this.values = [];
    this.length = 0;
  }

  clear() {
    this.length = 0;
  }

  push(id, value) {
    let index = this.length++;
    while (index > 0) {
      const parent = (index - 1) >> 1;
      const parentValue = this.values[parent];
      if (value >= parentValue) break;
      this.ids[index] = this.ids[parent];
      this.values[index] = parentValue;
      index = parent;
    }
    this.ids[index] = id;
    this.values[index] = value;
  }

  pop() {
    if (this.length === 0) return undefined;

    const result = this.ids[0];
    this.length--;

    if (this.length > 0) {
      const lastId = this.ids[this.length];
      const lastValue = this.values[this.length];
      const half = this.length >> 1;
      let index = 0;

      while (index < half) {
        let child = 1 + (index << 1);
        const right = child + 1;
        let childId = this.ids[child];
        let childValue = this.values[child];

        if (right < this.length && this.values[right] < childValue) {
          child = right;
          childId = this.ids[right];
          childValue = this.values[right];
        }

        if (childValue >= lastValue) break;
        this.ids[index] = childId;
        this.values[index] = childValue;
        index = child;
      }

      this.ids[index] = lastId;
      this.values[index] = lastValue;
    }

    return result;
  }

  peek() {
    return this.length === 0 ? undefined : this.ids[0];
  }

  peekValue() {
    return this.length === 0 ? undefined : this.values[0];
  }

  shrink() {
    this.ids.length = this.length;
    this.values.length = this.length;
  }
}
