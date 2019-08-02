import { observable } from 'mobx';
import { UserProfile } from './defs';

interface StoreInit {
  profile: UserProfile;
}

export class Store {
  @observable
  public profile: UserProfile;

  constructor(init: StoreInit) {
    this.profile = init.profile;
  }
}
