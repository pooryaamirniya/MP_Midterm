"""Live contract smoke test. Credentials are read locally and never printed.

Usage: python tools/api_smoke.py --account .private/account.json
Creates and removes its own playlist and restores the chosen track's favorite state.
"""
import argparse
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'https://soundify.easyfound.ir/api/v1'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--account', required=True)
    args = parser.parse_args()
    account = json.loads(Path(args.account).read_text(encoding='utf-8-sig'))
    token = None
    checks = []

    def call(method, path, body=None, expected=(200,), bearer=True):
        headers = {'Accept': 'application/json', 'Content-Type': 'application/json', 'User-Agent': 'Soundify/1.0'}
        if bearer and token:
            headers['Authorization'] = 'Bearer ' + token
        payload = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(BASE + path, data=payload, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=40) as r:
                status, data = r.status, r.read()
        except urllib.error.HTTPError as e:
            status, data = e.code, e.read()
        assert status in expected, f'{method} {path}: unexpected HTTP {status}'
        checks.append({'method': method, 'path': path, 'status': status})
        print(f'PASS {method} {path}: {status}', flush=True)
        return json.loads(data) if data else None

    pair = call('POST', '/auth/login', {'email': account['email'], 'password': account['password']}, bearer=False)
    token = pair['access']
    call('GET', '/users/me')
    catalog = call('GET', '/tracks?q=Coldplay&page_size=5')
    assert catalog['results'], 'Search returned no playable tracks'
    track = catalog['results'][0]
    favorites = call('GET', '/favorites?page_size=50')['results']
    was_favorite = any(t['id'] == track['id'] for t in favorites)
    playlist_id = None
    try:
        if not was_favorite:
            call('POST', '/favorites', {'track_id': track['id']}, expected=(201,))
            assert any(t['id'] == track['id'] for t in call('GET', '/favorites')['results'])
            call('DELETE', '/favorites/' + track['id'], expected=(204,))
        p = call('POST', '/playlists', {'name': 'Soundify contract test', 'description': 'Temporary test'}, expected=(201,))
        playlist_id = p['id']
        call('PATCH', f'/playlists/{playlist_id}', {'name': 'Updated test', 'description': 'Edit verified'})
        call('POST', f'/playlists/{playlist_id}/tracks', {'track_id': track['id']}, expected=(201,))
        details = call('GET', f'/playlists/{playlist_id}')
        assert details['name'] == 'Updated test' and details['tracks'][0]['id'] == track['id']
        call('DELETE', f'/playlists/{playlist_id}/tracks/{track["id"]}', expected=(204,))
        assert call('GET', f'/playlists/{playlist_id}')['tracks'] == []
        call('GET', '/playlists')
    finally:
        if playlist_id is not None:
            call('DELETE', f'/playlists/{playlist_id}', expected=(204,))
        if not was_favorite:
            call('DELETE', '/favorites/' + track['id'], expected=(204,))
    rotated = call('POST', '/auth/token/refresh', {'refresh': pair['refresh']}, bearer=False)
    token = rotated['access']
    call('GET', '/users/me')
    call('POST', '/auth/token/refresh', {'refresh': pair['refresh']}, expected=(401,), bearer=False)
    call('POST', '/auth/logout', {'refresh': rotated['refresh']}, expected=(204,))
    call('GET', '/users/me', expected=(401,))
    Path('docs/api-test-results.json').write_text(json.dumps({'tested_at_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'checks': checks}, indent=2), encoding='utf-8')
    print(f'All {len(checks)} live API checks passed; test data cleaned up.')

if __name__ == '__main__':
    main()
