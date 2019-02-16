import { observable, action } from 'mobx';

type Blind = '' | 'yes' | 'complete';

/**
 * Store of newroom page.
 */
export class NewRoomStore {
  /**
   * Whether description is shown.
   */
  @observable
  descriptionShown: boolean = false;
  /**
   * Whether form is disabled.
   */
  @observable
  formDisabled: boolean = false;
  /**
   * whether to use password.
   */
  @observable
  public usePassword: boolean = false;
  /**
   * blind mode
   */
  @observable
  public blind: Blind = '';
  /**
   * whether to use GM
   */
  @observable
  public gm: boolean = false;
  /**
   * whether to allow watcher's speak
   */
  @observable
  public watchSpeak: boolean = true;
  /**
   * Set whether description is shown.
   */
  @action
  public setDescriptionShown(value: boolean): void {
    this.descriptionShown = value;
  }
  /**
   * Set whether form is disabled.
   */
  @action
  public setFormDisabled(value: boolean): void {
    this.formDisabled = value;
  }
  /**
   * Update usepassword.
   */
  @action
  public setUsePassword(usePassword: boolean): void {
    this.usePassword = usePassword;
  }
  /**
   * Update blind.
   */
  @action
  public setBlind(blind: Blind): void {
    this.blind = blind;
  }
  /**
   * Update gm.
   */
  @action
  public setGm(gm: boolean): void {
    this.gm = gm;
  }
  /**
   * Update watchSPeak.
   */
  @action
  public setWatchSpeak(watchSpeak: boolean): void {
    this.watchSpeak = watchSpeak;
  }
}
