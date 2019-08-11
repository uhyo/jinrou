import React from 'react';
import { Store } from '../store';
import { useI18n } from '../../../i18n/react';
import { BanSectionWrapper } from './element';
import { FontAwesomeIcon } from '../../../util/icon';

interface Props {
  store: Store;
}

export const BanAlert: React.FunctionComponent<Props> = ({ store }) => {
  const t = useI18n('mypage_client');
  const { ban } = store;
  if (ban == null) {
    return null;
  }
  console.log(ban);
  return (
    <BanSectionWrapper>
      <div>
        <FontAwesomeIcon icon="exclamation-triangle" size="4x" />
      </div>
      <div>
        <p>{t('ban.announcement')}</p>
        <p>
          {t('ban.reason')} <b>{ban.reason}</b>
        </p>
        {ban.expires != null ? (
          <>
            <p>
              {t('ban.period')}{' '}
              <b>
                <ExpiryMessage expires={new Date(ban.expires)} />
              </b>
            </p>
            <p>{t('ban.notice')}</p>
          </>
        ) : null}
      </div>
    </BanSectionWrapper>
  );
};

const ExpiryMessage: React.FunctionComponent<{
  expires: Date;
}> = ({ expires }) => {
  const t = useI18n('mypage_client');

  const diff = (expires.getTime() - Date.now()) / 1e3;

  if (diff >= 86400) {
    // more than 1 day
    let days = Math.floor(diff / 86400);
    let hours = Math.ceil((diff % 86400) / 3600);
    if (hours === 24) {
      days++;
      hours = 0;
    }
    return t('ban.periodDayHour', {
      days,
      hours,
    });
  } else if (diff >= 3600) {
    // more than 1 hour
    let hours = Math.floor(diff / 3600);
    let minutes = Math.ceil((diff % 3600) / 60);
    if (minutes === 60) {
      hours++;
      minutes = 0;
    }
    return t('ban.periodHourMinute', {
      hours,
      minutes,
    });
  } else if (diff >= 60) {
    const minutes = Math.ceil(diff / 60);
    return t('ban.periodMinute', { minutes });
  } else {
    return t('ban.periodLessThanMinute');
  }
};
