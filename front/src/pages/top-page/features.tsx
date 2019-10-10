import { forwardRef } from 'react';
import React from 'react';
import {
  FeaturesSection,
  FeatureWrapper,
  FeatureIcon,
  FeatureTitle,
  FeatureDescription,
  FeaturesHeading,
} from './elements';
import { FontAwesomeIcon, IconProp } from '../../util/icon';
import { i18n } from '../../i18n';

interface Props {
  i18n: i18n;
}

interface FeatureObject {
  icon: IconProp;
  title: string;
  description: string[];
}

export const Features = forwardRef<HTMLElement, Props>(({ i18n }, ref) => {
  const features = i18n.getResource(
    i18n.language,
    'top_client',
    'features',
  ) as FeatureObject[];

  if (features.length === 0) {
    return null;
  }

  return (
    <FeaturesSection ref={ref}>
      <FeaturesHeading>{i18n.t('top_client:featuresTitle')}</FeaturesHeading>
      {features.map((feature, i) => (
        <FeatureWrapper key={i}>
          <FeatureIcon>
            <FontAwesomeIcon icon={feature.icon} size="3x" fixedWidth />
          </FeatureIcon>
          <FeatureTitle>{feature.title}</FeatureTitle>
          <FeatureDescription>
            {feature.description.map((line, j) => (
              <p key={j}>{line}</p>
            ))}
          </FeatureDescription>
        </FeatureWrapper>
      ))}
    </FeaturesSection>
  );
});
