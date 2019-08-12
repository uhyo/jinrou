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
      <NewsTable>
        <thead>
          <tr>
            <th>{t('news.date')}</th>
            <th>{t('news.message')}</th>
          </tr>
        </thead>
        <tbody>
          {newsIsLoading
            ? [0, 1, 2, 3, 4].map(idx => (
                <tr key={`placeholder${idx}`}>
                  <td />
                  <td>{t('news.loading')}</td>
                </tr>
              ))
            : newsEntries.map((entry, i) => {
                const time = new Date(entry.time);
                const year = time.getFullYear();
                const month = ('0' + (time.getMonth() + 1)).slice(-2);
                const day = ('0' + time.getDate()).slice(-2);
                return (
                  <tr key={i}>
                    <td>
                      {year}-{month}-{day}
                    </td>
                    <td>{entry.message}</td>
                  </tr>
                );
              })}
        </tbody>
      </NewsTable>
    </NewsSectionWrapper>
  );
});
