import styled from '../../util/styled';
import { AppStyling } from '../../styles/phone';
import { mediumBorderColor, helperTextColor } from '../../common/color';
import { pagePadding, formComponentsVerticalMergin } from '../../common/style';
import { phone } from '../../common/media';

export const AppWrapper = styled(AppStyling)`
  padding: ${pagePadding};
`;

/**
 * @internal
 */
export const ContentsWrapper = styled.div`
  display: flex;
  flex-flow: nowrap column;
  width: max-content;
  max-width: 100%;
`;

/**
 * Wrapper of forms
 * @internal
 */
export const FormWrapper = styled.form`
  box-sizing: border-box;
  width: 100%;
  max-width: 600px;
  margin: 0.5em 0;
  padding: 0.3em 1em;
  border: 1px solid ${mediumBorderColor};

  h2 {
    margin-top: 0;
  }
`;

/**
 * UL for notice.
 */
export const NoticeUl = styled.ul`
  margin: ${formComponentsVerticalMergin} 1em;
  list-style-type: disc;
  list-style-position: inside;
`;

/**
 * Line of warning.
 * Keeps its space even if no error is shown.
 * @internal
 */
export const ErrorLine = styled.p`
  height: 1.1em;
`;

// ---------- Features ----------

export const FeaturesSection = styled.section``;

export const FeaturesHeading = styled.h2`
  padding-bottom: 2px;
  font-size: 1.2em;
  font-weight: normal;
  color: ${helperTextColor};
  border-bottom: 1px solid ${mediumBorderColor};
`;

export const FeatureWrapper = styled.section`
  display: grid;
  grid-template:
    'icon title' auto
    'icon desc' auto / auto 1fr;
  margin: 1rem 0;

  ${phone`
    font-size: 0.93em;
  `};
`;

export const FeatureIcon = styled.div`
  grid-area: icon;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 1rem 1rem 1rem 0;
`;

export const FeatureTitle = styled.h3`
  grid-area: title;
  font-size: 1.1em;
  text-shadow: none;
`;
export const FeatureDescription = styled.div`
  grid-area: desc;
  color: ${helperTextColor};

  p {
    line-height: 1.3;
    text-align: justify;
  }
`;

// ---------- Footer ----------
/**
 * Footer of top page.
 * @internal
 */
export const Footer = styled.footer`
  font-size: smaller;
`;
