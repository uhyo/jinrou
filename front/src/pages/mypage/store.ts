import { observable, action } from 'mobx';
import { UserProfile, NewsEntry } from './defs';

interface StoreInit {
  profile: UserProfile;
  mailConfirmSecurity: boolean;
}

export class Store {
  @observable
  public profile: UserProfile;

  @observable
  public mailConfirmSecurity: boolean;

  @observable
  public newsIsLoading: boolean = true;

  @observable
  public newsEntries: NewsEntry[] = [];

  constructor(init: StoreInit) {
    this.profile = init.profile;
    this.mailConfirmSecurity = init.mailConfirmSecurity;
  }

  @action
  public gotNews(entries: NewsEntry[]) {
    this.newsIsLoading = false;
    this.newsEntries = entries;
  }
}
