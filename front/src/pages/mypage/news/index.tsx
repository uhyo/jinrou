import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import React from 'react';
import { Store } from '../store';
import { observer } from 'mobx-react-lite';
import { NewsSectionWrapper, NewsTable } from './elements';
import { useI18n } from '../../../i18n/react';

interface Props {
  store: Store;
}

export const News: React.FunctionComponent<Props> = observer(({ store }) => {
  const { newsIsLoading, newsEntries } = store;

  const t = useI18n('mypage_client');
  return (
    <NewsSectionWrapper isLoading={newsIsLoading}>
      <h2>
        <FontAwesomeIcon icon={['far', 'newspaper']} />
        {t('news.title')}
      </h2>
      {newsIsLoading ? (
        <p>{t('news.loading')}</p>
      ) : (
        <NewsTable>
          <thead>
            <tr>
              <th>{t('news.date')}</th>
              <th>{t('news.message')}</th>
            </tr>
          </thead>
          <tbody>
            {newsEntries.map((entry, i) => (
              <tr key={i}>
                <td>{entry.time}</td>
                <td>{entry.message}</td>
              </tr>
            ))}
          </tbody>
        </NewsTable>
      )}
    </NewsSectionWrapper>
  );
});
