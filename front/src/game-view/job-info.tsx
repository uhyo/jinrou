import * as React from 'react';
import styled from '../util/styled';

import {
    RoleInfo,
} from './defs';

const Wrapper = styled.div`
    margin: 5px;
    padding: 8px;
    border: 2px dashed currentColor;
`;

export interface IPropJobInfo extends RoleInfo { }

/**
 * Player's information.
 */
export class JobInfo extends React.PureComponent<IPropJobInfo, {}> {
    public render() {
        const {
            jobname,
            desc,
        } = this.props;

        console.log(desc);
        return (<Wrapper>
            <p>あなたは<b>{jobname}</b>です{
                desc.length === 0 ? null :
                /* XXX TypeScript bug. maybe fixed in TS 2.8? */
                (<>{'（'}{
                    [...mapJoin(
                        desc,
                        '・',
                        ((obj, idx)=> (<React.Fragment key={`${idx}-${obj.type}`}>
                            <a href={`/manual/job/${obj.type}`}>
                                {
                                    desc.length === 1 ? '詳細' : 
                                    `${obj.name}の詳細`
                                }
                            </a></React.Fragment>)),
                    )
                ]}）</>)
            }</p>
        </Wrapper>);
    }
}

/**
 * map and join given array.
 */
function* mapJoin<T, U>(arr: T[], join: string, func: (elm: T, idx: number)=> U): IterableIterator<U | string> {
    let idx = 0;
    for (const elm of arr) {
        if (idx > 0) {
            yield join;
        }
        yield func(elm, idx);
        idx++;
    }
}
