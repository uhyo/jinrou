import { SectionWrapper } from '../elements';
import styled from '../../../util/styled';
import { smallTextSize } from '../../../common/style';

export const BanSectionWrapper = styled(SectionWrapper)`
  display: flex;
  flex-flow: row nowrap;
  align-items: center;
  border: 1px dashed #888800;
  background-color: #ffffee;
  color: #333300;
  font-size: ${smallTextSize};

  div:first-child {
    margin-right: 1em;
  }

  p {
    margin: 0.2em 0;
  }
`;
