-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'riettabusiness@gmail.com' ,'andrewbrown' ,'afc0e30b-63ab-4b46-8aea-789cf14b10d9'),
  ('Andrew Bayko', 'ebikaeyimina@gmail.com' ,'bayko' ,'e78a9b5e-51ac-47f4-9df6-d73f33a4cb9e'),
  ('Tayo', 'henrietta2hotty@gmail.com' ,'tayo' ,'f0c2c3af-500e-4e0a-a3a7-df2df44f5543'),
  ('Londo Mollari','lmollari@centari.com' ,'londo' ,'MOCK');
  

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )