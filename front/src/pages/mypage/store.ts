import { observable } from 'mobx';
import { UserProfile } from './defs';

interface StoreInit {
  profile: UserProfile;
  mailConfirmSecurity: boolean;
}

export class Store {
  @observable
  public profile: UserProfile;

  @observable
  public mailConfirmSecurity: boolean;

  constructor(init: StoreInit) {
    this.profile = init.profile;
    this.mailConfirmSecurity = init.mailConfirmSecurity;
  }
}
