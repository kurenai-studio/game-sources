export default class Status {
  private _name: string;
  private _current_value: number;
  private _max_value = 100;
  private _min_value = 0;

  constructor(name: string, current_value: number) {
    this._name = name;
    this._current_value = current_value;
  }

  public get name(): string {
    return this._name;
  }

  public set current_value(value: number) {
    this._current_value = value;
  }

  public get current_value() {
    return this._current_value;
  }

  public get max_value() {
    return this._max_value;
  }

  public get min_value() {
    return this._min_value;
  }
}
