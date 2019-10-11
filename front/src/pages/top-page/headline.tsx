import React, { FunctionComponent, memo } from 'react';
import { useI18n } from '../../i18n/react';
import styled from '../../util/styled';
import { phone, IsPhone } from '../../common/media';
import { smallTextSize } from '../../common/style';

export const Headline: FunctionComponent<{
  onSeeFeature: (e: React.SyntheticEvent<HTMLAnchorElement>) => void;
}> = memo(({ onSeeFeature }) => {
  const t = useI18n('top_client');

  return (
    <HeadlineWrapper>
      <img src="/images/logo.png" width="116" height="106" />
      <div>
        <p>{t('app.description')}</p>
        <IsPhone>
          {isPhone =>
            isPhone ? (
              <p>
                <a className="no-jump" href="/" onClick={onSeeFeature}>
                  {t('app.featuresLink')}
                </a>
              </p>
            ) : null
          }
        </IsPhone>
      </div>
    </HeadlineWrapper>
  );
});

const HeadlineWrapper = styled.div`
  display: flex;
  flex-flow: row nowrap;
  align-items: center;
  color: white;
  background-color: #000865;

  img {
    flex: auto 0 0;

    width: 116px;
    height: 106px;

    ${phone`
      width: 58px;
      height: 53px;
    `};
  }

  p {
    margin: 0.3rem 0 0.3rem 2rem;
    ${phone`
      font-size: ${smallTextSize};
    `};
  }

  a {
    color: white;
  }
`;
