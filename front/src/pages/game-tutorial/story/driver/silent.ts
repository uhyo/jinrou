import { DriverBase } from './base';
import { Driver } from '../defs';

export class SilentDriver extends DriverBase implements Driver {
  get step() {
    return () => {};
  }
  public cancelStep() {
    this.cancellation.cancelAll();
  }
  public sleep: Driver['sleep'] = () => Promise.resolve();
  public messageDialog: Driver['messageDialog'] = () => Promise.resolve();
  public getSpeakHandler: Driver['getSpeakHandler'] = () => () => {};
  public getJoinHandler: Driver['getJoinHandler'] = () => () => {};
  public getUnjoinHandler: Driver['getUnjoinHandler'] = () => () => {};
  public getReadyHandler: Driver['getReadyHandler'] = () => () => {};
  public getRejectionHandler: Driver['getRejectionHandler'] = () => () => {};
}
