import styled from '../../util/styled';
import { AppStyling } from '../../styles/phone';
import { pagePadding, formComponentsVerticalMergin } from '../../common/style';
import { mediumBorderColor } from '../../common/color';
import { phone } from '../../common/media';

export const AppWrapper = styled(AppStyling)`
  padding: 0 ${pagePadding};
`;

export const SectionWrapper = styled.section`
  margin: ${formComponentsVerticalMergin} 0;
  padding: 0.3em 1em;
  border: 1px solid ${mediumBorderColor};

  ${phone`
    border: none;
    border-bottom: 1px solid ${mediumBorderColor};
  `};
`;
