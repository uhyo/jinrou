/**
 * Make a string representing given jobNumbers.
 */
export function makeJobsString(roles: string[], jobNumbers: Map<string, number>): string {
    // TODO
    return roles.map((id)=> {
        const val = jobNumbers.get(id) || 0;
        if (val > 0) {
            return `${id}: ${val}`;
        } else {
            return '';
        }
    }).join(' ');
}
