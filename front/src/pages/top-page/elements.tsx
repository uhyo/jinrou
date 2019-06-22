import styled from '../../util/styled';
import { AppStyling } from '../../styles/phone';
import { mediumBorderColor } from '../../common/color';
import { pagePadding, formComponentsVerticalMergin } from '../../common/style';

export const AppWrapper = styled(AppStyling)`
  padding: 0 ${pagePadding};
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
  max-width: 100%;
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

/**
 * Footer of top page.
 * @internal
 */
export const Footer = styled.footer`
  font-size: smaller;
`;
