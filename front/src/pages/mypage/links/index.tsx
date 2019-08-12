import React from 'react';
import { useI18n, I18nInterp } from '../../../i18n/react';
import {
  LinksWrapper,
  LinkElement,
  LinkTitle,
  LinkDescription,
  LineSeparator,
} from './elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { Store } from '../store';
import { observer } from 'mobx-react-lite';

export const Links: React.FunctionComponent<{
  store: Store;
}> = observer(({ store }) => {
  const t = useI18n('mypage_client');

  return (
    <LinksWrapper>
      <Link icon="list" href="/rooms" title={t('links.rooms.title')} />
      <Link
        icon="chart-pie"
        href="/my/log"
        title={t('links.mylog.title')}
        description={t('links.mylog.description')}
      />
      <Link
        long
        icon="award"
        href="/my/prize"
        title={t('links.prize.title')}
        description={() => (
          <div>
            <LinkDescription>{t('links.prize.description')}</LinkDescription>
            <LinkDescription>
              <I18nInterp ns="mypage_client" k="links.prize.number">
                {{
                  count: <b>{store.prize.totalNumber}</b>,
                }}
              </I18nInterp>
            </LinkDescription>
            {store.prize.currentPrizeData ? (
              <LinkDescription>
                <I18nInterp ns="mypage_client" k="links.prize.current">
                  {{
                    data: <b>{store.prize.currentPrizeData}</b>,
                  }}
                </I18nInterp>
              </LinkDescription>
            ) : null}
          </div>
        )}
      />
      <Separator />
      <Link
        icon="cog"
        href="/my/settings"
        title={t('links.settings.title')}
        description={t('links.settings.description')}
      />
      <Link
        icon="school"
        href="/tutorial/game"
        title={t('links.gameTutorial.title')}
        description={t('links.gameTutorial.description')}
      />
      <Link icon="door-open" href="/logout" title={t('links.logout.title')} />
    </LinksWrapper>
  );
});

const Link: React.FunctionComponent<{
  icon: React.ComponentProps<typeof FontAwesomeIcon>['icon'];
  long?: boolean;
  href: string;
  title: string;
  description?: string | (() => React.ReactNode);
}> = ({ icon, long, href, title, description }) => (
  <LinkElement href={href} long={long}>
    <FontAwesomeIcon icon={icon} size="3x" />
    <LinkTitle>{title}</LinkTitle>
    {typeof description === 'string' ? (
      <LinkDescription>{description}</LinkDescription>
    ) : typeof description === 'function' ? (
      description()
    ) : null}
  </LinkElement>
);

const Separator = () => <LineSeparator role="presentation" />;
