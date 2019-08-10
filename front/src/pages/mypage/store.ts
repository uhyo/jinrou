import { observable, action } from 'mobx';
import { UserProfile, NewsEntry, BanInfo } from './defs';

interface StoreInit {
  profile: UserProfile;
  mailConfirmSecurity: boolean;
  ban: BanInfo | null;
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

  @observable
  public ban: BanInfo | null;

  constructor(init: StoreInit) {
    this.profile = init.profile;
    this.mailConfirmSecurity = init.mailConfirmSecurity;
    this.ban = init.ban;
  }

  @action
  public gotNews(entries: NewsEntry[]) {
    this.newsIsLoading = false;
    this.newsEntries = entries;
  }
}
